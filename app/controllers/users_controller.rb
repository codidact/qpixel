require 'net/http'

# rubocop:disable Metrics/ClassLength
class UsersController < ApplicationController
  include Devise::Controllers::Rememberable

  before_action :authenticate_user!, only: [:edit_profile, :update_profile, :stack_redirect, :transfer_se_content,
                                            :qr_login_code, :me, :preferences, :set_preference, :my_vote_summary,
                                            :disconnect_sso, :confirm_disconnect_sso, :filters]
  before_action :verify_moderator, only: [:mod, :destroy, :soft_delete, :role_toggle, :full_log,
                                          :annotate, :annotations, :mod_privileges, :mod_privilege_action]
  before_action :set_user, only: [:show, :mod, :destroy, :soft_delete, :posts, :role_toggle, :full_log, :activity,
                                  :annotate, :annotations, :mod_privileges, :mod_privilege_action,
                                  :vote_summary, :network, :avatar]
  before_action :check_deleted, only: [:show, :posts, :activity]

  def index
    @sort_param = { reputation: :reputation, age: :created_at }[params[:sort]&.to_sym] || :reputation

    @users = if params[:search].present?
               user_scope.search(params[:search])
             else
               user_scope
             end

    @users = @users.where.not(deleted: true)
                   .where.not(community_users: { deleted: true })
                   .order(@sort_param => :desc)
                   .paginate(page: params[:page], per_page: 48)

    @post_counts = Post.where(user_id: @users.pluck(:id).uniq).group(:user_id).count

    respond_to do |format|
      format.html
      format.json do
        render json: @users
      end
    end
  end

  def show
    @abilities = Ability.on_user(@user)

    all_posts = if current_user&.privilege?('flag_curate') || @user == current_user
                  @user.posts
                else
                  @user.posts.undeleted
                end
                .list_includes
                .joins(:category)
                .where('IFNULL(categories.min_view_trust_level, 0) <= ?', current_user&.trust_level || 0)
                .user_sort({ term: params[:sort], default: :score },
                           age: :created_at, score: :score)

    @posts = all_posts.first(15)
    @total_post_count = all_posts.count
    render layout: 'without_sidebar'
  end

  def me
    @user = current_user
    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
      format.json do
        data = [:id, :username, :trust_level, :se_acct_id].to_h { |a| [a, @user.send(a)] }

        data_with_ac = data.merge({
                                    is_standard: @user.standard?,
                                    is_admin: @user.admin?,
                                    is_global_admin: @user.global_admin?,
                                    is_moderator: @user.at_least_moderator?,
                                    is_global_moderator: @user.at_least_global_moderator?
                                  })

        render json: data_with_ac
      end
    end
  end

  def preferences
    current_user.validate_prefs!
    respond_to do |format|
      format.html do
        prefs = current_user.preferences
        @preferences = prefs[:global]
        @community_prefs = prefs[:community]
        render layout: 'without_sidebar'
      end
      format.json do
        render json: current_user.preferences
      end
    end
  end

  # Helper method to convert it to the form expected by the client
  def filter_json(filter)
    {
      min_score: filter.min_score,
      max_score: filter.max_score,
      min_answers: filter.min_answers,
      max_answers: filter.max_answers,
      include_tags: Tag.where(id: filter.include_tags).map { |tag| [tag.name, tag.id] },
      exclude_tags: Tag.where(id: filter.exclude_tags).map { |tag| [tag.name, tag.id] },
      status: filter.status,
      system: filter.user_id == -1
    }
  end

  def filters_json
    system_filters = Rails.cache.fetch 'default_system_filters', expires_in: 1.day do
      User.find(-1).filters.to_h { |filter| [filter.name, filter_json(filter)] }
    end

    if user_signed_in?
      current_user.filters.to_h { |filter| [filter.name, filter_json(filter)] }
                  .merge(system_filters)
    else
      system_filters
    end
  end

  def filters
    respond_to do |format|
      format.html do
        render layout: 'without_sidebar'
      end
      format.json do
        render json: filters_json
      end
    end
  end

  def set_filter
    if user_signed_in? && params[:name]
      filter = Filter.find_or_create_by(user: current_user, name: params[:name])

      filter.update(filter_params)

      unless params[:category].nil? || params[:is_default].nil?
        helpers.set_filter_default(current_user.id, filter.id, params[:category].to_i, params[:is_default])
      end

      render json: { status: 'success', success: true, filters: filters_json },
             status: 200
    else
      render json: { status: 'failed', success: false, errors: ['Filter name is required'] },
             status: 400
    end
  end

  def delete_filter
    unless params[:name]
      return render json: { status: 'failed', success: false, errors: ['Filter name is required'] },
                    status: 400
    end

    as_user = current_user

    if params[:system] == true
      if current_user&.is_global_admin
        as_user = User.find(-1)
      else
        return render json: { status: 'failed', success: false, errors: ['You do not have permission to delete'] },
                      status: 400
      end
    end

    filter = Filter.find_by(user: as_user, name: params[:name])
    if filter.destroy
      render json: { status: 'success', success: true, filters: filters_json }
    else
      render json: { status: 'failed', success: false, errors: ['Failed to delete'] },
             status: 400
    end
  end

  def default_filter
    if user_signed_in? && params[:category]
      default_filter = helpers.default_filter(current_user.id, params[:category].to_i)
      render json: { status: 'success', success: true, name: default_filter&.name }
    else
      render json: { status: 'failed', success: false },
             status: :bad_request
    end
  end

  def set_preference
    if !params[:name].nil? && !params[:value].nil?
      global_key = "prefs.#{current_user.id}"
      community_key = "prefs.#{current_user.id}.community.#{RequestContext.community_id}"
      key = params[:community].present? && params[:community] ? community_key : global_key
      current_user.validate_prefs!
      render json: { status: 'success',
                     count: RequestContext.redis.hset(key, params[:name], params[:value].to_s),
                     preferences: current_user.preferences }
    else
      render json: { status: 'failed',
                     message: 'Failed to save the preference',
                     errors: ['Both name and value parameters are required'] },
             status: :bad_request
    end
  end

  def posts
    @posts = if current_user&.privilege?('flag_curate') || @user == current_user
               Post.all
             else
               Post.undeleted
             end.by(@user).list_includes.joins(:category)
             .where('IFNULL(categories.min_view_trust_level, 0) <= ?', current_user&.trust_level || 0)
             .user_sort({ term: params[:sort], default: :score },
                        activity: :last_activity,
                        age: :created_at,
                        score: :score)
             .paginate(page: params[:page], per_page: 25)
    respond_to do |format|
      format.html do
        render :posts
      end
      format.json do
        render json: @posts
      end
    end
  end

  def my_network
    redirect_to network_path(current_user)
  end

  def network
    @communities = Community.all
    render layout: 'without_sidebar'
  end

  def activity
    @posts = Post.undeleted.by(@user).count
    @comments = Comment.by(@user).joins(:comment_thread, :post).undeleted.where(comment_threads: { deleted: false },
                                                                                posts: { deleted: false }).count
    @suggested_edits = SuggestedEdit.by(@user).count
    @edits = PostHistory.by(@user).of_type('post_edited').on_undeleted.count

    @all_edits = @suggested_edits + @edits

    items = case params[:filter]
            when 'posts'
              Post.undeleted.by(@user)
            when 'comments'
              Comment.by(@user).joins(:comment_thread, :post).undeleted.where(comment_threads: { deleted: false },
                                                                              posts: { deleted: false })
            when 'edits'
              SuggestedEdit.by(@user) + PostHistory.by(@user).of_type('post_edited').on_undeleted
            else
              Post.undeleted.by(@user) +
              Comment.by(@user).joins(:comment_thread, :post).undeleted.where(comment_threads: { deleted: false },
                                                                              posts: { deleted: false }) +
              SuggestedEdit.by(@user).all +
              PostHistory.by(@user).on_undeleted.all
            end

    @items = items.sort_by(&:created_at).reverse.paginate(page: params[:page], per_page: 50)
    render layout: 'without_sidebar'
  end

  def mod; end

  def full_log
    @posts = Post.by(@user).count
    @comments = Comment.by(@user).count
    @flags = Flag.by(@user).count
    @suggested_edits = SuggestedEdit.by(@user).count
    @edits = PostHistory.by(@user).count
    @mod_warnings_received = ModWarning.to(@user).count

    @all_edits = @suggested_edits + @edits

    @interesting_comments = Comment.by(@user).deleted.count
    @interesting_flags = Flag.by(@user).declined.count
    @interesting_edits = SuggestedEdit.by(@user).rejected.count
    @interesting_posts = Post.by(@user).problematic.count

    @interesting = @interesting_comments + @interesting_flags + @mod_warnings_received +
                   @interesting_edits + @interesting_posts

    @items = (case params[:filter]
              when 'posts'
                Post.by(@user).all
              when 'comments'
                Comment.by(@user).all
              when 'flags'
                Flag.by(@user).all
              when 'edits'
                SuggestedEdit.by(@user).all + PostHistory.by(@user).all
              when 'warnings'
                ModWarning.to(@user).all
              when 'interesting'
                Comment.by(@user).deleted.all + Flag.by(@user).declined.all +
                  SuggestedEdit.by(@user).rejected.all +
                  Post.by(@user).problematic.all
              else
                Post.by(@user).all + Comment.by(@user).all + Flag.by(@user).all +
                  SuggestedEdit.by(@user).all + PostHistory.by(@user).all +
                  ModWarning.to(@user).all
              end).sort_by(&:created_at).reverse.paginate(page: params[:page], per_page: 50)

    render layout: 'without_sidebar'
  end

  def mod_privileges
    @abilities = Ability.all
  end

  def soft_delete
    if @user.at_least_moderator?
      render json: { status: 'failed', message: 'Admins and moderators cannot be deleted.' },
             status: :unprocessable_entity
      return
    end

    case params[:type]
    when 'profile'
      AuditLog.moderator_audit(event_type: 'profile_delete', related: @user.community_user, user: current_user,
                               comment: @user.community_user.attributes_print(join: "\n"))
      @user.community_user.update(deleted: true, deleted_by: current_user, deleted_at: DateTime.now)
    when 'user'
      unless current_user.is_global_moderator || current_user.is_global_admin
        render json: { status: 'failed', message: 'Non-global moderator cannot perform global deletion.' },
               status: 403
        return
      end

      @user.do_soft_delete(current_user)
    else
      render json: { status: 'failed', message: 'Unrecognised deletion type.' }, status: 400
      return
    end

    render json: { status: 'success', user: @user.id }
  end

  def edit_profile
    render layout: 'without_sidebar'
  end

  def cleaned_profile_websites(profile_params)
    sites = profile_params[:user_websites_attributes]

    sites.transform_values do |w|
      w.merge({ label: w[:label].presence, url: w[:url].presence })
    end
  end

  def update_profile
    profile_params = params.require(:user).permit(:username,
                                                  :profile_markdown,
                                                  :website,
                                                  :discord,
                                                  :twitter,
                                                  user_websites_attributes: [:id, :label, :url])

    if profile_params[:user_websites_attributes].present?
      profile_params[:user_websites_attributes] = cleaned_profile_websites(profile_params)
    end

    @user = current_user

    if params[:user][:avatar].present?
      if helpers.valid_upload?(params[:user][:avatar])
        @user.avatar.attach(params[:user][:avatar])
      else
        @user.errors.add(:avatar, 'must be a valid image')
        flash[:danger] = "Couldn't update your profile."
        render :edit_profile
        return
      end
    end

    if params[:user][:profile_markdown].present?
      profile_rendered = helpers.rendered_post(:user, :profile_markdown)
      profile_params = profile_params.merge(profile: profile_rendered)
    end

    status = @user.update(profile_params)

    if status
      flash[:success] = 'Your profile details were updated.'
      redirect_to user_path(current_user)
    else
      flash[:danger] = "Couldn't update your profile."
      render :edit_profile
    end
  end

  def role_toggle
    role_map = {
      mod: :is_moderator,
      admin: :is_admin,
      mod_global: :is_global_moderator,
      admin_global: :is_global_admin,
      staff: :staff
    }

    # values must match methods on the User model
    permission_map = {
      mod: :admin?,
      admin: :global_admin?,
      mod_global: :global_admin?,
      admin_global: :global_admin?,
      staff: :staff
    }

    unless role_map.keys.include?(params[:role].underscore.to_sym)
      render json: { status: 'error', message: "Role not found: #{params[:role]}" }, status: :bad_request
    end

    key = params[:role].underscore.to_sym
    attrib = role_map[key]
    permission = permission_map[key]
    return not_found! unless current_user.send(permission)

    case key
    when :mod
      new_value = !@user.community_user.send(attrib)

      # Set/update ability
      if new_value
        @user.community_user.grant_privilege!('mod')
      else
        @user.community_user.privilege('mod')&.destroy
      end

      @user.community_user.update(attrib => new_value)
    when :admin
      new_value = !@user.community_user.send(attrib)
      @user.community_user.update(attrib => new_value)
    else
      new_value = !@user.send(attrib)
      @user.update(attrib => new_value)
    end

    @user.community_user.recalc_trust_level

    AuditLog.admin_audit(event_type: 'role_toggle', related: @user, user: current_user,
                         comment: "#{attrib} to #{new_value}")
    AbilityQueue.add(@user, 'Role Change')

    render json: { status: 'success' }
  end

  def mod_privilege_action
    ability = Ability.find_by internal_id: params[:ability]
    return not_found! if ability.internal_id == 'mod'

    ua = @user.community_user.privilege(ability.internal_id)

    case params[:do]
    when 'grant'
      if ua.nil?
        @user.community_user.grant_privilege!(ability.internal_id)
        AuditLog.admin_audit(event_type: 'ability_grant', related: @user, user: current_user,
                             comment: ability.internal_id.to_s)
      elsif ua.is_suspended
        ua.update is_suspended: false
        AuditLog.admin_audit(event_type: 'ability_unsuspend', related: @user, user: current_user,
                             comment: "#{ability.internal_id} ability unsuspended")
      end

    when 'suspend'
      return not_found! if ua.nil?

      duration = params[:duration]&.to_i
      duration = duration <= 0 ? nil : duration.days.from_now
      message = params[:message]

      ua.update is_suspended: true, suspension_end: duration, suspension_message: message
      @user.create_notification("Your #{ability.name} ability has been suspended. Click for more information.",
                                ability_url(ability.internal_id))
      AuditLog.admin_audit(event_type: 'ability_suspend', related: @user, user: current_user,
                           comment: "#{ability.internal_id} ability suspended\n\n#{message}")

    when 'delete'
      return not_found! if ua.nil?

      ua.destroy
      AuditLog.admin_audit(event_type: 'ability_remove', related: @user, user: current_user,
                           comment: "#{ability.internal_id} ability removed")

      AuditLog.user_history(event_type: 'deleted_ability', related: nil, user: @user,
                            comment: ability.internal_id)
    else
      return not_found!
    end
    render json: { status: 'success' }
  end

  def stack_redirect
    response = Net::HTTP.post_form(URI('https://stackoverflow.com/oauth/access_token/json'),
                                   'client_id' => SiteSetting['SEApiClientId'],
                                   'client_secret' => SiteSetting['SEApiClientSecret'],
                                   'code' => params[:code], 'redirect_uri' => stack_redirect_url)
    access_token = JSON.parse(response.body)['access_token']

    uri = "https://api.stackexchange.com/2.2/me/associated?key=#{SiteSetting['SEApiKey']}" \
          "&access_token=#{access_token}&filter=!-rH86dva"
    accounts = JSON.parse(Net::HTTP.get(URI(uri)))
    network_id = accounts['items'][0]['account_id']
    current_user.update(se_acct_id: network_id)
    redirect_to edit_user_profile_path
  end

  def transfer_se_content
    unless params[:agree_to_relicense].present? && params[:agree_to_relicense] == 'true'
      flash[:danger] = 'To claim your content, we need you to agree to relicense your posts to us.'
      redirect_to(edit_user_profile_path) && return
    end

    auto_user = User.where(se_acct_id: current_user.se_acct_id).where.not(id: current_user.id).first
    if auto_user.nil?
      flash[:warning] = "There doesn't appear to be any of your content here."
      redirect_to(edit_user_profile_path) && return
    end

    community = RequestContext.community

    Thread.new do
      RequestContext.community = community

      ApplicationRecord.transaction do
        auto_user.posts.each do |post|
          post.reassign_user(current_user)
          post.remove_attribution_notice!
        end
        auto_user.reload.destroy
        current_user.update(transferred_content: true)
      end
    end
    flash[:success] = 'Your content is being transferred to you.'
    redirect_to edit_user_profile_path
  end

  def qr_login_code
    @token = SecureRandom.urlsafe_base64(64)
    @qr_code = RQRCode::QRCode.new(qr_login_url(@token))
    current_user.update(login_token: @token, login_token_expires_at: 5.minutes.from_now)
  end

  def do_qr_login
    user = User.find_by(login_token: params[:token])
    if user&.login_token_expires_at&.present? && user.login_token_expires_at >= DateTime.now
      flash[:success] = 'You are now signed in.'
      user.update(login_token: nil, login_token_expires_at: nil)
      sign_in user
      remember_me user
      AuditLog.user_history(event_type: 'mobile_login', related: user)
      redirect_to after_sign_in_path_for(user)
    else
      flash[:danger] = "That login link isn't valid. Codes expire after 5 minutes - if it's been longer than that, " \
                       'get a new code and try again.'
      not_found!
    end
  end

  def annotations
    @logs = AuditLog.where(log_type: 'user_annotation', related: @user)
                    .newest_first
                    .paginate(page: params[:page], per_page: 20)
    render layout: 'without_sidebar'
  end

  def annotate
    @log = AuditLog.user_annotation(event_type: 'annotation', user: current_user, related: @user,
                                    comment: params[:comment])
    if @log.errors.none?
      redirect_to user_annotations_path(@user)
    else
      flash[:danger] = 'Failed to save your annotation.'
      render :annotations
    end
  end

  def my_vote_summary
    redirect_to vote_summary_path(current_user)
  end

  def vote_summary
    @votes = Vote.for(@user).includes(:post).group(:date_of, :post_id, :vote_type)

    @votes = @votes.select(:post_id, :vote_type)
                   .select('count(*) as vote_count')
                   .select('date(votes.created_at) as date_of')

    @votes = @votes.order(date_of: :desc, post_id: :desc).all
                   .group_by(&:date_of).map do |k, vl|
                     [k, vl.group_by(&:post), vl.sum { |v| v.vote_type * v.vote_count }]
                   end
                   .paginate(page: params[:page], per_page: 15)

    render layout: 'without_sidebar'
  end

  def avatar
    respond_to do |format|
      format.png do
        size = params[:size]&.to_i&.positive? ? [params[:size]&.to_i, 256].min : 64
        send_data helpers.user_auto_avatar(size, user: @user).to_blob, type: 'image/png', disposition: 'inline'
      end
    end
  end

  def specific_avatar
    respond_to do |format|
      format.png do
        size = params[:size]&.to_i&.positive? ? params[:size]&.to_i : 64
        send_data helpers.user_auto_avatar(size, letter: params[:letter], color: params[:color]).to_blob,
                  type: 'image/png', disposition: 'inline'
      end
    end
  end

  def disconnect_sso
    render layout: 'without_sidebar'
  end

  def confirm_disconnect_sso
    if current_user.sso_profile.blank? || !helpers.devise_sign_in_enabled? || !SiteSetting['AllowSsoDisconnect']
      flash[:danger] = 'You cannot disable Single Sign-On.'
      redirect_to edit_user_registration_path
      return
    end

    if current_user.sso_profile.destroy
      current_user.send_reset_password_instructions
      flash[:success] = 'Successfully disconnected from Single Sign-On. Please see your email to set your password.'
      redirect_to edit_user_registration_path
    else
      flash[:danger] = 'Failed to disconnect from Single Sign-On.'
      redirect_to user_disconnect_sso_path
    end
  end

  private

  def filter_params
    params.permit(:min_score, :max_score, :min_answers, :max_answers, :status, :include_tags, :exclude_tags,
                  include_tags: [], exclude_tags: [])
  end

  def set_user
    user_id = if params[:id] == 'me' && user_signed_in?
                current_user.id
              else
                params[:id]
              end
    @user = user_scope.find_by(id: user_id)
    not_found! if @user.nil?
  end

  def user_scope
    User.accessible_to(current_user)
        .joins(:community_user)
        .includes(:community_user, :avatar_attachment)
  end

  def check_deleted
    deleted = @user.deleted? || @user.community_user.deleted?
    go_to_not_found = !current_user&.at_least_moderator? || params[:deleted_screen].present?

    if deleted && go_to_not_found
      render :deleted_user, layout: 'without_sidebar', status: 404
    end
  end
end
# rubocop:enable Metrics/ClassLength
