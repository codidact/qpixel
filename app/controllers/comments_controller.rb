# rubocop:disable Metrics/ClassLength
# Provides mainly web actions for using and making comments.
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:post, :show, :thread, :thread_content]

  before_action :set_comment, only: [:update, :destroy, :undelete, :show]
  before_action :set_post, only: [:create_thread]
  before_action :set_thread,
                only: [:create, :thread, :thread_content, :thread_rename, :thread_restrict, :thread_unrestrict,
                       :thread_followers]

  before_action :check_post_access, only: [:create_thread, :create]
  before_action :check_privilege, only: [:update, :destroy, :undelete]
  before_action :check_create_access, only: [:create_thread, :create]
  before_action :check_reply_access, only: [:create]
  before_action :check_restrict_access, only: [:thread_restrict]
  before_action :check_thread_access, only: [:thread, :thread_content, :thread_followers]
  before_action :check_unrestrict_access, only: [:thread_unrestrict]
  before_action :check_if_target_post_locked, only: [:create, :post_follow]
  before_action :check_if_parent_post_locked, only: [:update, :destroy]

  def create_thread
    title = params[:title]
    unless title.present?
      title = helpers.generate_thread_title(params[:body])
    end

    body = params[:body]

    @comment_thread = CommentThread.new(title: helpers.strip_markdown(title, strip_leading_quote: true), post: @post)
    @comment = Comment.new(post: @post, content: body, user: current_user, comment_thread: @comment_thread)

    pings = check_for_pings(@comment_thread, body)

    success = ActiveRecord::Base.transaction do
      thread_success = @comment_thread.save
      comment_success = @comment.save
      full_success = thread_success && comment_success

      unless full_success
        raise ActiveRecord::Rollback
      end

      full_success
    end

    if success
      notification = "New comment thread on #{@comment.root.title}: #{@comment_thread.title}"
      unless @comment.post.user == current_user
        @comment.post.user.create_notification(notification, helpers.comment_link(@comment))
      end

      ThreadFollower.where(post: @post).each do |tf|
        unless tf.user == current_user || tf.user == @comment.post.user
          tf.user.create_notification(notification, helpers.comment_link(@comment))
        end
        ThreadFollower.create(user: tf.user, comment_thread: @comment_thread)
      end

      apply_pings(pings)
    else
      flash[:danger] = "Could not create comment thread: #{(@comment_thread.errors.full_messages \
                                                           + @comment.errors.full_messages).join(', ')}"
    end
    redirect_to helpers.generic_share_link(@post)
  end

  def create
    body = params[:content]
    pings = check_for_pings(@comment_thread, body)

    @comment = Comment.new(post: @post, content: body, user: current_user,
                           comment_thread: @comment_thread, has_reference: false)

    status = @comment.save

    if status
      apply_pings(pings)
      @comment_thread.thread_follower.each do |follower|
        next if follower.user_id == current_user.id
        next if pings.include? follower.user_id

        thread_url = comment_thread_url(@comment_thread, host: @comment_thread.community.host)
        existing_notification = follower.user.notifications.where(is_read: false)
                                        .where('link LIKE ?', "#{thread_url}%")
        next if existing_notification.exists?

        title = @post.parent.nil? ? @post.title : @post.parent.title
        follower.user.create_notification("There are new comments in a followed thread '#{@comment_thread.title}' " \
                                          "on the post '#{title}'",
                                          helpers.comment_link(@comment))
      end
    else
      flash[:danger] = @comment.errors.full_messages.join(', ')
    end

    if params[:inline] == 'true'
      redirect_to helpers.generic_share_link(@post, comment_id: status ? @comment.id : nil,
                                                    thread_id: @comment_thread.id)
    else
      redirect_to comment_thread_path(@comment_thread.id)
    end
  end

  def update
    @post = @comment.post
    @comment_thread = @comment.comment_thread
    before = @comment.content
    before_pings = check_for_pings(@comment_thread, before)
    if @comment.update comment_params
      unless current_user.id == @comment.user_id
        audit('comment_update', @comment, "from <<#{before}>>\nto <<#{@comment.content}>>")
      end

      after_pings = check_for_pings(@comment_thread, @comment.content)
      apply_pings(after_pings - before_pings - @comment_thread.thread_follower.to_a)

      render json: { status: 'success',
                     comment: render_to_string(partial: 'comments/comment',
                                               locals: { comment: @comment, pingable: after_pings }) }
    else
      render json: { status: 'failed',
                     message: "Comment failed to save (#{@comment.errors.full_messages.join(', ')})" },
             status: :internal_server_error
    end
  end

  def destroy
    if @comment.update(deleted: true)
      @comment_thread = @comment.comment_thread

      unless current_user.id == @comment.user_id
        audit('comment_delete', @comment, "content <<#{@comment.content}>>")
      end

      respond_to do |format|
        format.html { redirect_to comment_thread_path(@comment_thread.id) }
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.html do
          flash[:danger] = I18n.t('comments.errors.delete_comment_server_error')
          redirect_to comment_thread_path(@comment_thread.id)
        end
        format.json { render json: { status: 'failed' }, status: :internal_server_error }
      end
    end
  end

  def undelete
    if @comment.update(deleted: false)
      @comment_thread = @comment.comment_thread

      unless current_user.id == @comment.user_id
        audit('comment_undelete', @comment, "content <<#{@comment.content}>>")
      end

      respond_to do |format|
        format.html { redirect_to comment_thread_path(@comment_thread.id) }
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.html do
          flash[:danger] = I18n.t('comments.errors.undelete_comment_server_error')
          redirect_to comment_thread_path(@comment_thread.id)
        end
        format.json { render json: { status: 'failed' }, status: :internal_server_error }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render partial: 'comments/comment', locals: { comment: @comment } }
      format.json { render json: @comment }
    end
  end

  def thread
    respond_to do |format|
      format.html { render 'comments/thread' }
      format.json { render json: @comment_thread }
    end
  end

  def thread_content
    render partial: 'comment_threads/expanded', locals: { inline: params[:inline] == 'true',
                                                          show_deleted: params[:show_deleted_comments] == '1',
                                                          thread: @comment_thread }
  end

  def thread_followers
    return not_found! unless current_user&.at_least_moderator?

    @followers = ThreadFollower.where(comment_thread: @comment_thread).joins(:user, user: :community_user)
                               .includes(:user, user: [:community_user, :avatar_attachment])
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @followers }
    end
  end

  def thread_rename
    if @comment_thread.read_only? && !current_user.at_least_moderator?
      flash[:danger] = 'This thread has been locked.'
      redirect_to comment_thread_path(@comment_thread.id)
      return
    end

    title = helpers.strip_markdown(params[:title], strip_leading_quote: true)
    status = @comment_thread.update(title: title)

    unless status
      flash[:danger] = I18n.t('comments.errors.rename_thread_generic')
    end

    redirect_to comment_thread_path(@comment_thread.id)
  end

  def thread_restrict
    case params[:type]
    when 'lock'
      lu = nil
      unless params[:duration].blank?
        lu = params[:duration].to_i.days.from_now
      end
      @comment_thread.update(locked: true, locked_by: current_user, locked_until: lu)
    when 'archive'
      @comment_thread.update(archived: true, archived_by: current_user)
    when 'delete'
      @comment_thread.update(deleted: true, deleted_by: current_user)
    when 'follow'
      ThreadFollower.create comment_thread: @comment_thread, user: current_user
    else
      return not_found!
    end

    render json: { status: 'success' }
  end

  def thread_unrestrict
    case params[:type]
    when 'lock'
      @comment_thread.update(locked: false, locked_by: nil, locked_until: nil)
    when 'archive'
      @comment_thread.update(archived: false, archived_by: nil, ever_archived_before: true)
    when 'delete'
      if @comment_thread.deleted_by.at_least_moderator? && !current_user.at_least_moderator?
        render json: { status: 'error', message: I18n.t('comments.errors.mod_only_undelete') }
        return
      end
      @comment_thread.update(deleted: false, deleted_by: nil)
    when 'follow'
      tf = ThreadFollower.find_by(comment_thread: @comment_thread, user: current_user)
      tf&.destroy
    else
      return not_found!
    end

    render json: { status: 'success' }
  end

  def post
    @post = Post.find(params[:post_id])
    @comment_threads = if current_user&.at_least_moderator? || current_user&.post_privilege?('flag_curate', @post)
                         CommentThread
                       else
                         CommentThread.undeleted
                       end.where(post: @post).order(deleted: :asc, archived: :asc, reply_count: :desc)
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @comment_threads }
    end
  end

  def post_follow
    @post = Post.find(params[:post_id])
    if ThreadFollower.where(post: @post, user: current_user).none?
      ThreadFollower.create(post: @post, user: current_user)
    end
    redirect_to post_path(@post)
  end

  def post_unfollow
    @post = Post.find(params[:post_id])
    ThreadFollower.where(post: @post, user: current_user).destroy_all
    redirect_to post_path(@post)
  end

  def pingable
    thread = params[:id] == '-1' ? CommentThread.new(post_id: params[:post]) : CommentThread.find(params[:id])
    users = User.where(id: thread.pingable)
    render json: users.to_h { |u| [u.username, u.id] }
  end

  private

  def comment_params
    params.require(:comment).permit(:content, :post_id)
  end

  def set_comment
    @comment = Comment.unscoped.find params[:id]
  end

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_thread
    @comment_thread = CommentThread.find(params[:id])
    @post = @comment_thread.post
  end

  def check_post_access
    if !@post.comments_allowed? && current_user&.standard?
      respond_to do |format|
        format.html { render template: 'errors/forbidden', status: :forbidden }
        format.json do
          message = helpers.comments_post_error_msg(@post)
          render json: { status: 'failed', message: message },
                 status: :forbidden
        end
      end
    elsif !@post.can_access?(current_user)
      not_found!
    end
  end

  def check_thread_access
    not_found! unless @comment_thread.can_access?(current_user)
  end

  def check_privilege
    unless current_user&.at_least_moderator? || current_user == @comment.user
      render template: 'errors/forbidden', status: :forbidden
    end
  end

  def check_create_access
    rate_limited, limit_message = helpers.comment_rate_limited?(current_user, @post)
    if rate_limited
      flash[:danger] = limit_message
      redirect_to helpers.generic_share_link(@post)
    end
  end

  def check_reply_access
    if @comment_thread.read_only? && current_user&.standard?
      respond_to do |format|
        format.html { render template: 'errors/forbidden', status: :forbidden }
        format.json do
          message = helpers.comments_thread_error_msg(@comment_thread)
          render json: { status: 'failed', message: message },
                 status: :forbidden
        end
      end
    end
  end

  def check_restrict_access
    case params[:type]
    when 'lock'
      not_found! unless current_user.can_lock?(@comment_thread)
    when 'archive'
      not_found! unless current_user.can_archive?(@comment_thread)
    when 'delete'
      not_found! unless current_user.can_delete?(@comment_thread)
    end
  end

  def check_unrestrict_access
    case params[:type]
    when 'lock'
      not_found! unless current_user.can_unlock?(@comment_thread)
    when 'archive'
      not_found! unless current_user.can_unarchive?(@comment_thread)
    when 'delete'
      not_found! unless current_user.can_undelete?(@comment_thread)
    end
  end

  def check_if_parent_post_locked
    check_if_locked(@comment.post)
  end

  def check_if_target_post_locked
    check_if_locked(Post.find(params[:post_id]))
  end

  # @param thread [CommentThread] thread to extract pings for
  # @param content [String] content to extract pings from
  # @return [Array<Integer>] list of pinged user ids
  def check_for_pings(thread, content)
    pingable = thread.pingable
    matches = content.scan(/@#(\d+)/)
    matches.flatten.select { |m| pingable.include?(m.to_i) }.map(&:to_i)
  end

  # @param pings [Array<Integer>] list of pinged user ids
  def apply_pings(pings)
    pings.each do |p|
      user = User.where(id: p).first
      next if user.nil?

      next if user.id == @comment.post.user_id

      title = @post.parent.nil? ? @post.title : @post.parent.title
      user.create_notification("You were mentioned in a comment in the thread '#{@comment_thread.title}' " \
                               "on the post '#{title}'",
                               helpers.comment_link(@comment))
    end
  end

  # @param event_type [String] audit log event type
  # @param comment [Comment] comment the audit is about
  # @param audit_comment [String] additional info to log
  def audit(event_type, comment, audit_comment = '')
    AuditLog.moderator_audit(event_type: event_type,
                             comment: audit_comment,
                             related: comment,
                             user: current_user)
  end
end
# rubocop:enable Metrics/ClassLength
