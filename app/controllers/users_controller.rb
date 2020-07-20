require 'net/http'

class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:edit_profile, :update_profile, :stack_redirect, :transfer_se_content,
                                            :qr_login_code, :me]
  before_action :verify_moderator, only: [:mod, :destroy, :soft_delete, :role_toggle, :full_log]
  before_action :set_user, only: [:show, :mod, :destroy, :soft_delete, :posts, :role_toggle, :full_log, :activity]

  def index
    sort_param = { reputation: :reputation, age: :created_at }[params[:sort]&.to_sym] || :reputation
    @users = if params[:search].present?
               user_scope.search(params[:search])
             else
               user_scope.order(sort_param => :desc)
             end.paginate(page: params[:page], per_page: 48)
    @post_counts = Post.where(user_id: @users.pluck(:id).uniq).group(:user_id).count
  end

  def show
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
                :se_acct_id].map { |a| [a, @user.send(a)] }.to_h
        render json: data
      end
    end
  end

  def posts
    @posts = Post.undeleted.where(user: @user).user_sort({ term: params[:sort], default: :score },
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

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def activity
    @posts = Post.undeleted.where(user: @user).count
    @comments = Comment.undeleted.where(user: @user).where(post: Post.undeleted).count
    @suggested_edits = SuggestedEdit.where(user: @user).count
    @edits = PostHistory.where(user: @user).where(post: Post.undeleted).count

    @all_edits = @suggested_edits + @edits

    items = case params[:filter]
            when 'posts'
              Post.undeleted.where(user: @user).all
            when 'comments'
              Comment.undeleted.where(user: @user).where(post: Post.undeleted).all
            when 'edits'
              SuggestedEdit.where(user: @user).all + PostHistory.where(user: @user).where(post: Post.undeleted)
            else
              Post.undeleted.where(user: @user).all + \
              Comment.undeleted.where(user: @user).where(post: Post.undeleted).all + \
              SuggestedEdit.where(user: @user).all + PostHistory.where(user: @user).where(post: Post.undeleted)
            end

    @items = items.sort_by(&:created_at).reverse
    render layout: 'without_sidebar'
  end

  def mod; end

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
                  Post.where(user: @user).where('score < 0.25 OR deleted=1').all
              else
                Post.where(user: @user).all + Comment.where(user: @user).all + Flag.where(user: @user).all + \
                  SuggestedEdit.where(user: @user).all + PostHistory.where(user: @user).all + \
                  ModWarning.where(community_user: @user.community_user).all
              end).sort_by(&:created_at).reverse

    render layout: 'without_sidebar'
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def destroy
    if @user.votes.count > 100
      render(json: { status: 'failed', message: 'Users with more than 100 votes cannot be destroyed.' }, status: 422)
      return
    end

    if @user.is_admin || @user.is_moderator
      render(json: { status: 'failed', message: 'Admins and moderators cannot be destroyed.' }, status: 422)
      return
    end

    before = @user.attributes_print
    if @user.destroy!
      AuditLog.moderator_audit(event_type: 'user_destroy', user: current_user, comment: "<<User #{before}>>")
      render json: { status: 'success' }
    else
      render json: { status: 'failed',
                     message: 'Call to <code>@user.destroy!</code> failed; ask a DBA or dev to destroy.' },
             status: 500
    end
  end

  def soft_delete
    if @user.is_admin || @user.is_moderator
      render(json: { status: 'failed', message: 'Admins and moderators cannot be deleted.' }, status: 422)
      return
    end

    relations = User.reflections
    transfer_id = SiteSetting['SoftDeleteTransferId']
    relations.select { |_, ref| ref.options[:dependent] == :destroy }.each do |name, ref|
      if ref.macro == :has_many || ref.macro == :has_and_belongs_to_many
        @user.send(name).destroy_all
      else
        @user.send(name).destroy
      end
    end
    relations.reject { |_, ref| ref.options[:dependent] == :destroy }.each do |name, ref|
      if ref.macro == :has_many || ref.macro == :has_and_belongs_to_many
        @user.send(name)&.update_all(ref.foreign_key => transfer_id)
      else
        @user.send(name)&.update(ref.foreign_key => transfer_id)
      end
    end

    before = @user.attributes_print
    unless @user.destroy
      render(json: { status: 'failed', message: "Failed to destroy UID #{@user.id}" }, status: 500)
      return
    end
    AuditLog.moderator_audit(event_type: 'user_delete', user: current_user, comment: "<<User #{before}>>")

    render json: { status: 'success', message: 'Ask a database administrator to verify the deletion is complete.' }
  end

  def edit_profile; end

  def update_profile
    profile_params = params.require(:user).permit(:username, :profile_markdown, :website, :twitter)
    profile_params[:twitter] = profile_params[:twitter].delete('@')

    if profile_params[:website].present? && URI.parse(profile_params[:website]).instance_of?(URI::Generic)
      # URI::Generic indicates the user didn't include a protocol, so we'll add one now so that it can be
      # parsed correctly in the view later on.
      profile_params[:website] = 'https://' + profile_params[:website]
    end

    @user = current_user
    before = @user.attributes_print

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

    profile_rendered = helpers.render_markdown(profile_params[:profile_markdown])
    if @user.update(profile_params.merge(profile: profile_rendered))
      flash[:success] = 'Your profile details were updated.'
      AuditLog.user_history(event_type: 'profile_update', related: @user, user: current_user,
                            comment: "from <<User #{before}>>\nto <<User #{@user.attributes_print}>>")
      redirect_to user_path(current_user)
    else
      flash[:danger] = "Couldn't update your profile."
      render :edit_profile
    end
  end

  def role_toggle
    if params[:role] == 'mod'
      @user.community_user.update(is_moderator: !@user.is_moderator)
      AuditLog.admin_audit(event_type: 'role_toggle', related: @user, user: current_user,
                           comment: "moderator to #{@user.is_moderator}")
      render json: { status: 'success' } && return
    end

    if current_user.is_global_admin
      if params[:role] == 'admin'
        @user.community_user.update(is_admin: !@user.is_admin)
        AuditLog.admin_audit(event_type: 'role_toggle', related: @user, user: current_user,
                             comment: "admin to #{@user.is_admin}")
        render json: { status: 'success' } && return
      end

      if params[:role] == 'mod-global'
        @user.update(is_global_moderator: !@user.is_global_moderator)
        AuditLog.admin_audit(event_type: 'role_toggle', related: @user, user: current_user,
                             comment: "global mod to #{@user.is_global_moderator}")
        render json: { status: 'success' } && return
      end

      if params[:role] == 'admin-global'
        @user.update(is_global_admin: true)
        AuditLog.admin_audit(event_type: 'role_toggle', related: @user, user: current_user,
                             comment: "global admin to #{@user.is_global_admin}")
        render json: { status: 'success' } && return
      end
    end

    render json: { status: 'error', message: "Role not found: #{params[:role]}" }
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

      auto_user.posts.each do |post|
        post.reassign_user(current_user)
        post.remove_attribution_notice!
      end
      auto_user.reload.destroy
      current_user.update(transferred_content: true)
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
      AuditLog.user_history(event_type: 'mobile_login', related: user)
      redirect_to root_path
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

  private

  def set_user
    @user = user_scope.find_by(id: params[:id])
    not_found if @user.nil?
  end

  def user_scope
    User.joins(:community_user).includes(:community_user, :avatar_attachment)
  end
end
