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
  before_action :stop_the_awful_troll

  helper_method :top_level_post_types, :second_level_post_types

  def upload
    redirect_to helpers.upload_remote_url(params[:key])
  end

  def dashboard
    @communities = Community.all
    render layout: 'without_sidebar'
  end

  def keyboard_tools; end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :profile, :website, :twitter])
  end

  def not_found(**add)
    respond_to do |format|
      format.html do
        render 'errors/not_found', layout: 'without_sidebar', status: :not_found
      end
      format.json do
        render json: { status: 'failed', success: false, errors: ['not_found'] }.merge(add), status: :not_found
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
        format.html { render 'errors/locked', layout: 'without_sidebar', status: :unauthorized }
        format.json { render json: { status: 'failed', message: 'Post is locked.' }, status: :unauthorized }
      end
    end
  end

  def top_level_post_types
    Rails.cache.fetch 'top_level_post_types' do
      PostType.where(is_top_level: true).select(:id).map(&:id)
    end
  end

  def second_level_post_types
    Rails.cache.fetch 'second_level_post_types' do
      PostType.where(is_top_level: false, has_parent: true).select(:id).map(&:id)
    end
  end

  def check_edits_limit!(post)
    recent_edits = SuggestedEdit.where(created_at: 24.hours.ago..Time.zone.now, user: current_user) \
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

    @first_visit_notice = !user_signed_in? && cookies[:dismiss_fvn] != 'true' ? true : false

    if current_user&.is_admin
      Rack::MiniProfiler.authorize_request
    end
  end

  def setup_request_context
    RequestContext.clear!

    host_name = request.raw_host_with_port # include port to support multiple localhost instances
    RequestContext.community = @community = Rails.cache.fetch("#{host_name}/community", expires_in: 1.hour) do
      Community.find_by(host: host_name)
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
    @pinned_links = Rails.cache.fetch("#{RequestContext.community_id}/pinned_links", expires_in: 2.hours) do
      Rack::MiniProfiler.step 'pinned_links: cache miss' do
        PinnedLink.where(active: true).where('shown_before IS NULL OR shown_before > NOW()').all
      end
    end
    @hot_questions = Rails.cache.fetch("#{RequestContext.community_id}/hot_questions", expires_in: 4.hours) do
      Rack::MiniProfiler.step 'hot_questions: cache miss' do
        Post.undeleted.where(last_activity: (Rails.env.development? ? 365 : 7).days.ago..Time.zone.now)
            .where(post_type_id: [Question.post_type_id, Article.post_type_id])
            .joins(:category).where(categories: { use_for_hot_posts: true })
            .where('score >= ?', SiteSetting['HotPostsScoreThreshold'])
            .order('score DESC').limit(SiteSetting['HotQuestionsCount']).all
      end
    end
  end

  def pull_categories
    @header_categories = Rails.cache.fetch("#{RequestContext.community_id}/header_categories") do
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
end
