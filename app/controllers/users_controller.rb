require 'net/http'

# rubocop:disable Metrics/ClassLength
class UsersController < ApplicationController
  include Devise::Controllers::Rememberable

  before_action :authenticate_user!, only: [:edit_profile, :update_profile, :stack_redirect, :transfer_se_content,
                                            :qr_login_code, :me, :preferences, :set_preference, :my_vote_summary,
                                            :disconnect_sso, :confirm_disconnect_sso]
  before_action :verify_moderator, only: [:mod, :destroy, :soft_delete, :role_toggle, :full_log,
                                          :annotate, :annotations, :mod_privileges,
                                          :mod_privilege_action, :mod_delete, :mod_reset_profile,
                                          :mod_clear_profile, :mod_escalation, :mod_escalate,
                                          :mod_contact, :mod_message]
  before_action :verify_global_moderator, only: [:mod_destroy, :global_log]
  before_action :set_user, only: [:show, :mod, :destroy, :soft_delete, :posts, :role_toggle,
                                  :full_log, :activity,
                                  :annotate, :annotations, :mod_privileges, :mod_privilege_action,
                                  :vote_summary, :avatar, :mod_delete, :mod_destroy,
                                  :mod_reset_profile, :mod_clear_profile, :mod_escalation,
                                  :mod_escalate, :mod_contact, :mod_message, :global_log]
  before_action :check_deleted, only: [:show, :posts, :activity]

  def index
    sort_param = { reputation: :reputation, age: :created_at }[params[:sort]&.to_sym] || :reputation
    @users = if params[:search].present?
               user_scope.search(params[:search])
             else
               user_scope.order(sort_param => :desc)
             end.where.not(deleted: true).where.not(community_users: { deleted: true })
                .paginate(page: params[:page], per_page: 48) # rubocop:disable Layout/MultilineMethodCallIndentation
    @post_counts = Post.where(user_id: @users.pluck(:id).uniq).group(:user_id).count
  end

  def show
    @abilities = Ability.on_user(@user)
    @posts = if current_user&.privilege?('flag_curate')
               @user.posts
             else
               @user.posts.undeleted
             end.list_includes.joins(:category)
             .where('IFNULL(categories.min_view_trust_level, 0) <= ?', current_user&.trust_level || 0)
             .order(score: :desc).first(15)
    render layout: 'without_sidebar'
  end

  def me
    @user = current_user
    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
      format.json do
        data = [:id, :username, :is_moderator, :is_admin, :is_global_moderator, :is_global_admin, :trust_level,
                :se_acct_id].to_h { |a| [a, @user.send(a)] }
        render json: data
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
    system_filters = Rails.cache.fetch 'system_filters' do
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
      format.html
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
      render json: { status: 'success', success: true, name: default_filter&.name },
             status: 200
    else
      render json: { status: 'failed', success: false },
             status: 400
    end
  end

  def set_preference
    if !params[:name].nil? && !params[:value].nil?
      global_key = "prefs.#{current_user.id}"
      community_key = "prefs.#{current_user.id}.community.#{RequestContext.community_id}"
      key = params[:community].present? && params[:community] ? community_key : global_key
      current_user.validate_prefs!
      render json: { status: 'success', success: true,
                     count: RequestContext.redis.hset(key, params[:name], params[:value].to_s),
                     preferences: current_user.preferences }
    else
      render json: { status: 'failed', success: false, errors: ['Both name and value parameters are required'] },
             status: 400
    end
  end

  def posts
    @posts = if current_user&.privilege?('flag_curate')
               Post.all
             else
               Post.undeleted
             end.where(user: @user).list_includes.joins(:category)
             .where('IFNULL(categories.min_view_trust_level, 0) <= ?', current_user&.trust_level || 0)
             .user_sort({ term: params[:sort], default: :score },
                        age: :created_at, score: :score)
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

  def activity
    @posts = Post.undeleted.where(user: @user).count
    @comments = Comment.joins(:comment_thread, :post).undeleted.where(user: @user, comment_threads: { deleted: false },
                                                                      posts: { deleted: false }).count
    @suggested_edits = SuggestedEdit.where(user: @user).count
    @edits = PostHistory.joins(:post, :post_history_type).where(user: @user, posts: { deleted: false },
                                                                post_history_types: { name: 'post_edited' }).count

    @all_edits = @suggested_edits + @edits

    items = case params[:filter]
            when 'posts'
              Post.undeleted.where(user: @user)
            when 'comments'
              Comment.joins(:comment_thread, :post).undeleted.where(user: @user, comment_threads: { deleted: false },
                                                                    posts: { deleted: false })
            when 'edits'
              SuggestedEdit.where(user: @user) + \
              PostHistory.joins(:post, :post_history_type).where(user: @user, posts: { deleted: false },
                                                                 post_history_types: { name: 'post_edited' })
            else
              Post.undeleted.where(user: @user) + \
              Comment.joins(:comment_thread, :post).undeleted.where(user: @user, comment_threads: { deleted: false },
                                                                    posts: { deleted: false }) + \
              SuggestedEdit.where(user: @user).all + \
              PostHistory.joins(:post).where(user: @user, posts: { deleted: false }).all
            end

    @items = items.sort_by(&:created_at).reverse
    render layout: 'without_sidebar'
  end

  def mod
    render layout: 'without_sidebar'
  end

  def mod_escalation
    @flag = Flag.new(post_flag_type: nil, reason: '', post_id: @user.id, post_type: 'User', user: current_user)
    render layout: 'without_sidebar'
  end

  def mod_escalate
    @flag = Flag.create(post_flag_type: nil, reason: params[:flag][:reason], post_id: @user.id,
                        post_type: 'User', user: current_user, escalated: true,
                        escalated_by: current_user, escalated_at: DateTime.now,
                        escalation_comment: '(escalated via Contact Community Team Tool)')
    FlagMailer.with(flag: @flag).flag_escalated.deliver_now
    flash[:success] = 'Thank you for your message. We have been notified and are looking into it.'
    redirect_to mod_user_path(@user)
  end

  def mod_contact
    render layout: 'without_sidebar'
  end

  def mod_message
    title = params[:title]
    unless title.present?
      title = 'Private Moderator Message'
    end

    body = params[:body]

    @comment_thread = CommentThread.new(title: title, post: nil, is_private: true)
    @comment = Comment.new(post: nil, content: body, user: current_user, comment_thread: @comment_thread)

    success = ActiveRecord::Base.transaction do
      @comment_thread.save!
      @comment.save!
      ThreadFollower.create! comment_thread: @comment_thread, user: @user
    end

    if success
      @user.create_notification("You have received a moderator message: #{@comment_thread.title}",
                                helpers.comment_link(@comment))
      redirect_to comment_thread_path(@comment_thread.id)
    else
      flash[:danger] = "Could not create comment thread: #{(@comment_thread.errors.full_messages \
                                                           + @comment.errors.full_messages).join(', ')}"
      render :mod_contact, layout: 'without_sidebar'
    end
  end

  def full_log
    @posts = Post.where(user: @user).count
    @comments = Comment.where(user: @user).count
    @flags = Flag.where(user: @user).count
    @suggested_edits = SuggestedEdit.where(user: @user).count
    @edits = PostHistory.where(user: @user).count
    @mod_warnings_received = ModWarning.where(community_user: @user.community_user).count

    @all_edits = @suggested_edits + @edits

    @interesting_comments = Comment.where(user: @user, deleted: true).count
    @interesting_flags = Flag.where(user: @user, status: 'declined').count
    @interesting_edits = SuggestedEdit.where(user: @user, active: false, accepted: false).count
    @interesting_posts = Post.where(user: @user).where('score < 0.25 OR deleted=1').count

    @interesting = @interesting_comments + @interesting_flags + @mod_warnings_received + \
                   @interesting_edits + @interesting_posts

    @items = (case params[:filter]
              when 'posts'
                Post.where(user: @user).all
              when 'comments'
                Comment.where(user: @user).all
              when 'flags'
                Flag.where(user: @user).all
              when 'edits'
                SuggestedEdit.where(user: @user).all + PostHistory.where(user: @user).all
              when 'warnings'
                ModWarning.where(community_user: @user.community_user).all
              when 'interesting'
                Comment.where(user: @user, deleted: true).all + Flag.where(user: @user, status: 'declined').all + \
                  SuggestedEdit.where(user: @user, active: false, accepted: false).all + \
                  Post.where(user: @user).where('score < 0.25 OR deleted=1').all + \
                  ModWarning.where(community_user: @user.community_user).all
              else
                Post.where(user: @user).all + Comment.where(user: @user).all + Flag.where(user: @user).all + \
                  SuggestedEdit.where(user: @user).all + PostHistory.where(user: @user).all + \
                  ModWarning.where(community_user: @user.community_user).all
              end).sort_by(&:created_at).reverse

    render layout: 'without_sidebar'
  end

  def global_log
    @posts = Post.unscoped.where(user: @user).count
    @comments = Comment.unscoped.where(user: @user).count
    @flags = Flag.unscoped.where(user: @user).count
    @suggested_edits = SuggestedEdit.unscoped.where(user: @user).count
    @edits = PostHistory.unscoped.where(user: @user).count
    @mod_warnings_received = ModWarning.where(community_user: @user.community_users).count + \
                             ModWarning.where(user: @user).count

    @all_edits = @suggested_edits + @edits

    @interesting_comments = Comment.unscoped.where(user: @user, deleted: true).count
    @interesting_flags = Flag.unscoped.where(user: @user, status: 'declined').count
    @interesting_edits = SuggestedEdit.unscoped.where(user: @user, active: false, accepted: false).count
    @interesting_posts = Post.unscoped.where(user: @user).where('score < 0.25 OR deleted=1').count

    @interesting = @interesting_comments + @interesting_flags + @mod_warnings_received + \
                   @interesting_edits + @interesting_posts

    @items = (case params[:filter]
              when 'posts'
                Post.unscoped.where(user: @user).all
              when 'comments'
                Comment.unscoped.where(user: @user).all
              when 'flags'
                Flag.unscoped.where(user: @user).all
              when 'edits'
                SuggestedEdit.unscoped.where(user: @user).all + \
                  PostHistory.where(user: @user).all
              when 'warnings'
                ModWarning.where(community_user: @user.community_users).all + \
                  ModWarning.where(user: @user).all
              when 'interesting'
                Comment.unscoped.where(user: @user, deleted: true).all + \
                  Flag.unscoped.where(user: @user, status: 'declined').all + \
                  SuggestedEdit.unscoped.where(user: @user, active: false, accepted: false).all + \
                  Post.unscoped.where(user: @user).where('score < 0.25 OR deleted=1').all + \
                  ModWarning.unscoped.where(community_user: @user.community_users).all + \
                  ModWarning.where(user: @user).all
              else
                Post.unscoped.where(user: @user).all + \
                  Comment.unscoped.where(user: @user).all + \
                  Flag.unscoped.where(user: @user).all + \
                  SuggestedEdit.unscoped.where(user: @user).all + \
                  PostHistory.unscoped.where(user: @user).all + \
                  ModWarning.unscoped.where(community_user: @user.community_users).all + \
                  ModWarning.where(user: @user).all
              end).sort_by(&:created_at).reverse

    render layout: 'without_sidebar'
  end

  def mod_privileges
    @abilities = Ability.all
    render layout: 'without_sidebar'
  end

  def mod_reset_profile
    render layout: 'without_sidebar'
  end

  def mod_clear_profile
    before = @user.attributes_print
    @user.update(username: "user#{@user.id}", profile: '', website: '', twitter: '',
                 profile_markdown: '', discord: '')
    @user.create_notification('Your profile has been reset by a moderator. Click on this ' \
                              'notification to update your profile.', edit_user_profile_path)
    AuditLog.moderator_audit(event_type: 'profile_clear', user: current_user, comment: "<<User #{before}>>",
                             related: @user)
    redirect_to mod_user_path(@user)
  end

  def mod_delete
    render layout: 'without_sidebar'
  end

  def mod_destroy
    render layout: 'without_sidebar'
  end

  def destroy
    if @user.votes.count > 100
      render json: { status: 'failed', message: 'Users with more than 100 votes cannot be destroyed.' },
             status: :unprocessable_entity
      return
    end

    if @user.is_admin || @user.is_moderator
      render json: { status: 'failed', message: 'Admins and moderators cannot be destroyed.' },
             status: :unprocessable_entity
      return
    end

    before = @user.attributes_print
    @user.block('user destroyed')

    if @user.destroy
      Post.unscoped.where(user_id: @user.id).update_all(user_id: SiteSetting['SoftDeleteTransferUser'],
                                                        deleted: true, deleted_at: DateTime.now,
                                                        deleted_by_id: SiteSetting['SoftDeleteTransferUser'])
      Comment.unscoped.where(user_id: @user.id).update_all(user_id: SiteSetting['SoftDeleteTransferUser'],
                                                           deleted: true)
      Flag.unscoped.where(user_id: @user.id).update_all(user_id: SiteSetting['SoftDeleteTransferUser'])
      SuggestedEdit.unscoped.where(user_id: @user.id).update_all(user_id: SiteSetting['SoftDeleteTransferUser'])
      AuditLog.moderator_audit(event_type: 'user_destroy', user: current_user, comment: "<<User #{before}>>")
      render json: { status: 'success' }
    else
      render json: { status: 'failed',
                     message: 'Failed to destroy user; ask a dev.' },
             status: :internal_server_error
    end
  end

  def soft_delete
    if @user.is_admin || @user.is_moderator
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

      AuditLog.moderator_audit(event_type: 'user_delete', related: @user, user: current_user,
                               comment: @user.attributes_print(join: "\n"))
      @user.assign_attributes(deleted: true, deleted_by_id: current_user.id, deleted_at: DateTime.now,
                              username: "user#{@user.id}", email: "#{@user.id}@deleted.localhost",
                              password: SecureRandom.hex(32))
      @user.skip_reconfirmation!
      @user.save
    else
      render json: { status: 'failed', message: 'Unrecognised deletion type.' }, status: 400
      return
    end

    render json: { status: 'success', user: @user.id }
  end

  def edit_profile
    render layout: 'without_sidebar'
  end

  def update_profile
    profile_params = params.require(:user).permit(:username, :profile_markdown, :website, :twitter, :discord)
    profile_params[:twitter] = profile_params[:twitter].delete('@')

    if profile_params[:website].present? && URI.parse(profile_params[:website]).instance_of?(URI::Generic)
      # URI::Generic indicates the user didn't include a protocol, so we'll add one now so that it can be
      # parsed correctly in the view later on.
      profile_params[:website] = "https://#{profile_params[:website]}"
    end

    @user = current_user

    if params[:user][:avatar].present?
      if helpers.valid_image?(params[:user][:avatar])
        @user.avatar.attach(params[:user][:avatar])
      else
        @user.errors.add(:avatar, 'must be a valid image')
        flash[:danger] = "Couldn't update your profile."
        render :edit_profile
        return
      end
    end

    profile_rendered = helpers.post_markdown(:user, :profile_markdown)
    if @user.update(profile_params.merge(profile: profile_rendered))
      flash[:success] = 'Your profile details were updated.'
      redirect_to user_path(current_user)
    else
      flash[:danger] = "Couldn't update your profile."
      render :edit_profile
    end
  end

  def role_toggle
    role_map = { mod: :is_moderator, admin: :is_admin, mod_global: :is_global_moderator, admin_global: :is_global_admin,
                 staff: :staff }
    permission_map = { mod: :is_admin, admin: :is_global_admin, mod_global: :is_global_admin,
    admin_global: :is_global_admin, staff: :staff }
    unless role_map.keys.include?(params[:role].underscore.to_sym)
      render json: { status: 'error', message: "Role not found: #{params[:role]}" }, status: :bad_request
    end

    key = params[:role].underscore.to_sym
    attrib = role_map[key]
    permission = permission_map[key]
    return not_found unless current_user.send(permission)

    case key
    when :mod
      new_value = !@user.community_user.send(attrib)

      # Set/update ability
      if new_value
        @user.community_user.grant_privilege 'mod'
      else
        @user.community_user.privilege('mod').destroy
      end

      @user.community_user.update(attrib => new_value)
    when :admin
      new_value = !@user.community_user.send(attrib)
      @user.community_user.update(attrib => new_value)
    else
      new_value = !@user.send(attrib)
      @user.update(attrib => new_value)
    end
    AuditLog.admin_audit(event_type: 'role_toggle', related: @user, user: current_user,
                         comment: "#{attrib} to #{new_value}")
    AbilityQueue.add(@user, 'Role Change')

    render json: { status: 'success' }
  end

  def mod_privilege_action
    ability = Ability.find_by internal_id: params[:ability]
    return not_found if ability.internal_id == 'mod'

    ua = @user.community_user.privilege(ability.internal_id)

    case params[:do]
    when 'grant'
      if ua.nil?
        @user.community_user.grant_privilege(ability.internal_id)
        AuditLog.admin_audit(event_type: 'ability_grant', related: @user, user: current_user,
                             comment: ability.internal_id.to_s)
      elsif ua.is_suspended
        ua.update is_suspended: false
        AuditLog.admin_audit(event_type: 'ability_unsuspend', related: @user, user: current_user,
                             comment: "#{ability.internal_id} ability unsuspended")
      end

    when 'suspend'
      return not_found if ua.nil?

      duration = params[:duration]&.to_i
      duration = duration <= 0 ? nil : duration.days.from_now
      message = params[:message]

      ua.update is_suspended: true, suspension_end: duration, suspension_message: message
      @user.create_notification("Your #{ability.name} ability has been suspended. Click for more information.",
                                ability_url(ability.internal_id))
      AuditLog.admin_audit(event_type: 'ability_suspend', related: @user, user: current_user,
                           comment: "#{ability.internal_id} ability suspended\n\n#{message}")

    when 'delete'
      return not_found if ua.nil?

      ua.destroy
      AuditLog.admin_audit(event_type: 'ability_remove', related: @user, user: current_user,
                           comment: "#{ability.internal_id} ability removed")

      AuditLog.user_history(event_type: 'deleted_ability', related: nil, user: @user,
                            comment: ability.internal_id)
    else
      return not_found
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
      not_found
    end
  end

  def annotations
    @logs = AuditLog.where(log_type: 'user_annotation', related: @user).order(created_at: :desc)
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
    @votes = Vote.where(recv_user: @user) \
                 .includes(:post).group(:date_of, :post_id, :vote_type)
    @votes = @votes.select(:post_id, :vote_type) \
                   .select('count(*) as vote_count') \
                   .select('date(created_at) as date_of')
    @votes = @votes.order(date_of: :desc, post_id: :desc).all \
                   .group_by(&:date_of).map do |k, vl|
                     [k, vl.group_by(&:post), vl.sum { |v| v.vote_type * v.vote_count }]
                   end \
                   .paginate(page: params[:page], per_page: 15)
    render layout: 'without_sidebar'
  end

  def avatar
    respond_to do |format|
      format.png do
        size = params[:size]&.to_i&.positive? ? params[:size]&.to_i : 64
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
    @user = user_scope.find_by(id: params[:id])
    not_found if @user.nil?
  end

  def user_scope
    if helpers.moderator?
      User.all
    else
      User.active
    end.joins(:community_user).includes(:community_user, :avatar_attachment)
  end

  def check_deleted
    if (@user.deleted? || @user.community_user.deleted?) && (!helpers.moderator? || params[:deleted_screen].present?)
      render :deleted_user, layout: 'without_sidebar', status: 404
    end
  end
end
# rubocop:enable Metrics/ClassLength
