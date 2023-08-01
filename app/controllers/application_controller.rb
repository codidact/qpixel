# Application controller. This is the overarching control center for the application, which every web controller
# inherits from. Any application-wide code-based configuration is done here, as well as providing controller helper
# methods and global callbacks.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_globals
  before_action :check_if_warning_or_suspension_pending
  before_action :distinguish_fake_community
  before_action :stop_the_awful_troll

  # Before checking 2fa enforcing or access, store the location that the user is trying to access.
  # In case re-authentication is necessary / the user signs in, we can direct back to this location directly.
  before_action :store_user_location!, if: :storable_location?

  before_action :enforce_2fa
  before_action :block_write_request, if: :read_only_mode?

  helper_method :top_level_post_types, :second_level_post_types

  def upload
    if ActiveStorage::Blob.service.class.name.end_with?('S3Service')
      redirect_to helpers.upload_remote_url(params[:key]), status: 301, allow_other_host: true
    else
      blob = params[:key]
      redirect_to url_for(ActiveStorage::Blob.find_by(key: blob.is_a?(String) ? blob : blob.key)),
                  allow_other_host: true
    end
  end

  def dashboard
    @communities = Community.all
    render layout: 'without_sidebar'
  end

  def keyboard_tools; end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:profile, :website, :twitter])
  end

  def not_found(**add)
    respond_to do |format|
      format.json do
        render json: { status: 'failed', success: false, errors: ['not_found'] }.merge(add), status: :not_found
      end
      format.any do
        render 'errors/not_found', layout: 'without_sidebar', status: :not_found
      end
    end
    false
  end

  def verify_moderator
    if !user_signed_in? || !(current_user.is_moderator || current_user.is_admin)
      respond_to do |format|
        format.html do
          render 'errors/not_found', layout: 'without_sidebar', status: :not_found
        end
        format.json do
          render json: { status: 'failed', success: false, errors: ['not_found'] }, status: :not_found
        end
      end

      return false
    end
    true
  end

  def verify_admin
    if !user_signed_in? || !current_user.is_admin
      render 'errors/not_found', layout: 'without_sidebar', status: :not_found
      return false
    end
    true
  end

  def verify_global_admin
    if !user_signed_in? || !current_user.is_global_admin
      render 'errors/not_found', layout: 'without_sidebar', status: :not_found
      return false
    end
    true
  end

  def verify_global_moderator
    if !user_signed_in? || !(current_user.is_global_moderator || current_user.is_global_admin)
      render 'errors/not_found', layout: 'without_sidebar', status: :not_found
      return false
    end
    true
  end

  def verify_developer
    if !user_signed_in? || !current_user.developer?
      render 'errors/not_found', layout: 'without_sidebar', status: :not_found
      return false
    end
    true
  end

  def check_your_privilege(name, post = nil, render_error = true)
    unless current_user&.privilege?(name) || (current_user&.has_post_privilege?(name, post) if post)
      @privilege = Ability.find_by(name: name)
      render 'errors/forbidden', layout: 'without_sidebar', privilege_name: name, status: :forbidden if render_error
      return false
    end
    true
  end

  def check_if_locked(post)
    return if current_user.is_moderator

    if post.locked?
      respond_to do |format|
        format.html { render 'errors/locked', layout: 'without_sidebar', status: :forbidden }
        format.json { render json: { status: 'failed', message: 'Post is locked.' }, status: :forbidden }
      end
    end
  end

  def top_level_post_types
    helpers.post_type_ids(is_top_level: true)
  end

  def second_level_post_types
    helpers.post_type_ids(is_top_level: false, has_parent: true)
  end

  def check_edits_limit!(post)
    recent_edits = SuggestedEdit.where(created_at: 24.hours.ago..DateTime.now, user: current_user) \
                                .where('active = TRUE OR accepted = FALSE').count

    max_edits = SiteSetting[if current_user.privilege?('unrestricted')
                              'RL_SuggestedEdits'
                            else
                              'RL_NewUserSuggestedEdits'
                            end]

    edit_limit_msg = if current_user.privilege? 'unrestricted'
                       "You may only suggest #{max_edits} edits per day."
                     else
                       "You may only suggest #{max_edits} edits per day. " \
                         'Once you have some well-received posts, that limit will increase.'
                     end

    if recent_edits >= max_edits
      post.errors.add :base, edit_limit_msg
      AuditLog.rate_limit_log(event_type: 'suggested_edits', related: post, user: current_user,
                              comment: "limit: #{max_edits}")
      render :edit, status: :bad_request
      return true
    end
    false
  end

  private

  def distinguish_fake_community
    if RequestContext.community.is_fake
      return redirect_to :fc_communities if request.fullpath == '/'

      unless devise_controller? || ['fake_community', 'admin', 'users', 'site_settings'].include?(controller_name)
        not_found
      end
    else
      return not_found if ['fake_community'].include?(controller_name)
    end
  end

  def stop_the_awful_troll
    # There shouldn't be any trolls in the test environment... :D
    return true if Rails.env.test?

    # Only stop trolls doing things, not looking at them.
    return true if request.method.upcase == 'GET'

    # Trolls can't be awful without user accounts. User model is already checking for creation cases.
    return true if current_user.nil?

    ip = current_user.extract_ip_from(request)
    email_domain = current_user.email.split('@')[-1]

    ip_block = BlockedItem.active.where(item_type: 'ip', value: ip)
    mail_block = BlockedItem.active.where(item_type: 'email', value: current_user.email)
    mail_host_block = BlockedItem.active.where(item_type: 'email_host', value: email_domain)
    is_blocked = ip_block.or(mail_block).or(mail_host_block)

    if is_blocked.any?
      blocked_info = "ip: #{ip}\nemail: #{current_user.email}\ndomain: #{email_domain}"
      request_info = "request: #{request.method.upcase} #{request.fullpath}"
      params_info = params.except(*Rails.application.config.filter_parameters).permit!.to_h
                          .map { |k, v| "  #{k}: #{v}" }.join("\n")
      AuditLog.block_log(event_type: 'write_request_blocked', related: is_blocked.first,
                         comment: "#{blocked_info}\n#{request_info}\n#{params_info}")

      respond_to do |format|
        format.html { render 'errors/stat', layout: 'without_sidebar', status: 418 }
        format.json { render json: { status: 'failed', message: ApplicationRecord.useful_err_msg.sample }, status: 418 }
      end
      return false
    end
    true
  end

  def set_globals
    setup_request_context || return
    setup_user

    pull_pinned_links_and_hot_questions
    pull_categories

    if user_signed_in? && current_user.is_moderator
      @open_flags = Flag.unhandled.count
    end

    @first_visit_notice = !user_signed_in? && cookies[:dismiss_fvn] != 'true'

    if current_user&.is_admin
      Rack::MiniProfiler.authorize_request
    end
  end

  def setup_request_context
    RequestContext.clear!

    host_name = request.raw_host_with_port # include port to support multiple localhost instances
    RequestContext.community = @community = Rails.cache.fetch("#{host_name}/community", expires_in: 1.hour) do
      Community.unscoped.find_by(host: host_name)
    end

    Rails.logger.info "  Host #{host_name}, community ##{RequestContext.community_id} " \
                      "(#{RequestContext.community&.name})"
    if RequestContext.community.blank?
      render status: :unprocessable_entity, plain: "No community record matching Host='#{host_name}'"
      return false
    end

    true
  end

  def setup_user
    if current_user.nil?
      Rails.logger.info '  No user signed in'
    else
      Rails.logger.info "  User #{current_user.id} (#{current_user.username}) signed in"
      RequestContext.user = current_user
      current_user.ensure_community_user!
    end
  end

  def pull_pinned_links_and_hot_questions
    @pinned_links = Rails.cache.fetch('pinned_links', expires_in: 2.hours) do
      Rack::MiniProfiler.step 'pinned_links: cache miss' do
        PinnedLink.where(active: true).where('shown_before IS NULL OR shown_before > NOW()').all
      end
    end

    # We need to filter out pinned links that aren't posts
    # If pinned_post_ids contains nil, then the query formed is
    # SELECT WHERE NOT IN (... NULL)
    # In SQL, when the rhs of IN contains NULL, it returns NULL if not present, rather than false
    # Secondly, NOT NULL evaluates to NULL
    # These two counterintuitive behaviors mean that if NULL is in pinned_post_ids,
    # Post not pinned => NOT IN pinned_post_ids = NOT NULL = NULL => Not Selected
    # Post pinned => NOT IN pinned_post_ids = NOT TRUE = FALSE => Not Selected
    # I.e., if pinned_post_ids contains null, the selection will never return records
    pinned_post_ids = @pinned_links.map(&:post_id).compact

    @hot_questions = Rails.cache.fetch('hot_questions', expires_in: 4.hours) do
      Rack::MiniProfiler.step 'hot_questions: cache miss' do
        Post.undeleted.where(closed: false)
            .where(locked: false)
            .where(last_activity: (Rails.env.development? ? 365 : 7).days.ago..DateTime.now)
            .where(post_type_id: [Question.post_type_id, Article.post_type_id])
            .joins(:category).where(categories: { use_for_hot_posts: true })
            .where('score >= ?', SiteSetting['HotPostsScoreThreshold'])
            .where.not(id: pinned_post_ids)
            .order('score DESC').limit(SiteSetting['HotQuestionsCount']).all
      end
    end
  end

  def pull_categories
    @header_categories = Rails.cache.fetch('header_categories') do
      Category.all.order(sequence: :asc, id: :asc)
    end
  end

  def check_if_warning_or_suspension_pending
    return if current_user.nil?

    warning = ModWarning.where(community_user: current_user.community_user, active: true).any?
    return unless warning

    # Ignore devise and warning routes
    return if devise_controller? || ['custom_sessions', 'mod_warning', 'errors'].include?(controller_name)

    flash.clear

    redirect_to(current_mod_warning_path)
  end

  def enforce_2fa
    if current_user &&
       !current_user.enabled_2fa? &&
       Rails.env.production? &&
       # Don't enforce 2fa auth unless the setting is enabled
       SiteSetting['EnableMandatoryGlobalAdminMod2FA'] &&
       # Enable users to log out even if 2fa is enforced
       !request.fullpath.end_with?('/users/sign_out') &&
       (current_user.is_global_admin ||
         current_user.is_global_moderator) &&
       (current_user.sso_profile.blank? || SiteSetting['Enable2FAForSsoUsers'])
      redirect_path = '/users/two-factor'
      unless request.fullpath.end_with?(redirect_path)
        flash[:notice] = 'All global admins and global moderators must enable two-factor authentication to continue' \
                         'using this site. Please do so below'
        redirect_to(redirect_path)
      end
    end
  end

  def block_write_request(**add)
    respond_to do |format|
      format.html do
        render 'errors/read_only', layout: 'without_sidebar', status: :not_found
      end
      format.json do
        render json: { status: 'failed', success: false, errors: ['read_only'] }.merge(add), status: :locked
      end
    end
  end

  def read_only_mode?
    helpers.read_only? && request.method.upcase == 'POST'
  end

  def current_user
    helpers.current_user
  end

  def user_signed_in?
    helpers.user_signed_in?
  end

  def sso_sign_in_enabled?
    helpers.sso_sign_in_enabled?
  end

  def devise_sign_in_enabled?
    helpers.devise_sign_in_enabled?
  end

  def authenticate_user!(_fav = nil, **_opts)
    unless user_signed_in?
      respond_to do |format|
        format.html do
          flash[:error] = 'You need to sign in or sign up to continue.'
          if devise_sign_in_enabled?
            redirect_to new_user_session_path
          else
            redirect_to new_saml_user_session_path
          end
        end
        format.json do
          render json: { error: 'You need to sign in or sign up to continue.' }, status: 401
        end
      end
    end
  end

  # Checks if the requested location should be stored.
  #
  # Its important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
  #    infinite redirect loop.
  # - The request is an Ajax request as this can lead to very unexpected behaviour.
  # - The request is to a location we dont want to store, such as:
  #   - Anything trying to fetch for the current user (filters, preferences, etc) as it is not the actual page
  #   - The mobile login, as it would redirect to the code url after the sign in
  #   - Uploaded files, as these appear in posts and are not the main route we would want to store
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? &&
      !request.path.start_with?('/users/me') &&
      !request.path.start_with?('/users/mobile-login') &&
      !request.path.start_with?('/uploads/')
  end

  # Stores the location in the system for the current session, such that after login we send them back to the same page.
  def store_user_location!
    store_location_for(:user, request.fullpath)
  end
end
