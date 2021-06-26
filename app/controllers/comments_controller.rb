# Provides mainly web actions for using and making comments.
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:post, :show, :thread]
  before_action :set_comment, only: [:update, :destroy, :undelete, :show]
  before_action :set_thread, only: [:thread, :thread_rename, :thread_restrict, :thread_unrestrict, :thread_followers]
  before_action :check_privilege, only: [:update, :destroy, :undelete]
  before_action :check_if_target_post_locked, only: [:create]
  before_action :check_if_parent_post_locked, only: [:update, :destroy]

  def create_thread
    @post = Post.find(params[:post_id])
    if @post.comments_disabled && !current_user.is_moderator && !current_user.is_admin
      render json: { status: 'failed', message: 'Comments have been disabled on this post.' }, status: :forbidden
      return
    elsif !@post.can_access?(current_user)
      return not_found
    end

    title = params[:title]
    unless title.present?
      title = if params[:body].length > 100
                "#{params[:body][0..100]}..."
              else
                params[:body]
              end
    end

    body = params[:body]

    @comment_thread = CommentThread.new(title: title, post: @post)
    @comment = Comment.new(post: @post, content: body, user: current_user, comment_thread: @comment_thread)

    pings = check_for_pings @comment_thread, body

    return if comment_rate_limited

    success = ActiveRecord::Base.transaction do
      @comment_thread.save!
      @comment.save!
    end

    if success
      unless @comment.post.user == current_user
        @comment.post.user.create_notification("New comment thread on #{@comment.root.title}: #{@comment_thread.title}",
                                               helpers.comment_link(@comment))
      end

      apply_pings pings
    else
      flash[:danger] = "Could not create comment thread: #{(@comment_thread.errors.full_messages \
                                                           + @comment.errors.full_messages).join(', ')}"
    end
    redirect_to helpers.generic_show_link(@post)
  end

  def create
    @comment_thread = CommentThread.find(params[:id])
    @post = @comment_thread.post
    if @post.comments_disabled && !current_user.is_moderator && !current_user.is_admin
      render json: { status: 'failed', message: 'Comments have been disabled on this post.' }, status: :forbidden
      return
    elsif !@post.can_access?(current_user)
      return not_found
    end

    body = params[:content]
    pings = check_for_pings @comment_thread, body

    @comment = Comment.new(post: @post, content: body, user: current_user,
                           comment_thread: @comment_thread, has_reference: false)

    return if comment_rate_limited

    if @comment.save
      apply_pings pings
      @comment_thread.thread_follower.each do |follower|
        next if follower.user_id == current_user.id
        next if pings.include? follower.user_id

        existing_notification = follower.user.notifications.where(is_read: false)
                                        .where('link LIKE ?', "#{helpers.comment_link(@comment)}%")
        unless existing_notification.exists?
          follower.user.create_notification("There are new comments in a followed thread '#{@comment_thread.title}'",
                                            helpers.comment_link(@comment))
        end
      end
    else
      flash[:danger] = @comment.errors.full_messages.join(', ')
    end
    redirect_to comment_thread_path(@comment_thread.id)
  end

  def update
    before = @comment.content
    if @comment.update comment_params
      unless current_user.id == @comment.user_id
        AuditLog.moderator_audit(event_type: 'comment_update', related: @comment, user: current_user,
                                 comment: "from <<#{before}>>\nto <<#{@comment.content}>>")
      end
      render json: { status: 'success',
                     comment: render_to_string(partial: 'comments/comment', locals: { comment: @comment }) }
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
        AuditLog.moderator_audit(event_type: 'comment_delete', related: @comment, user: current_user,
                                 comment: "content <<#{@comment.content}>>")
      end
      render json: { status: 'success' }
    else
      render json: { status: 'failed' }, status: :internal_server_error
    end
  end

  def undelete
    if @comment.update(deleted: false)
      @comment_thread = @comment.comment_thread
      unless current_user.id == @comment.user_id
        AuditLog.moderator_audit(event_type: 'comment_undelete', related: @comment, user: current_user,
                                 comment: "content <<#{@comment.content}>>")
      end
      render json: { status: 'success' }
    else
      render json: { status: 'failed' }, status: :internal_server_error
    end
  end

  def show
    respond_to do |format|
      format.html { render partial: 'comments/comment', locals: { comment: @comment } }
      format.json { render json: @comment }
    end
  end

  def thread
    not_found unless @comment_thread.can_access?(current_user)
  end

  def thread_followers
    return not_found unless @comment_thread.can_access?(current_user)
    return not_found unless current_user.is_moderator || current_user.is_admin

    @followers = ThreadFollower.where(comment_thread: @comment_thread).joins(:user, user: :community_user)
                               .includes(:user, user: [:community_user, :avatar_attachment])
    respond_to do |format|
      format.json do
        render json: @followers
      end
      format.html do
        render layout: false
      end
    end
  end

  def thread_rename
    if @comment_thread.read_only? && !current_user.is_moderator
      flash[:danger] = 'This thread has been locked.'
      redirect_to comment_thread_path(@comment_thread.id)
      return
    end

    @comment_thread.update title: params[:title]
    redirect_to comment_thread_path(@comment_thread.id)
  end

  def thread_restrict
    case params[:type]
    when 'lock'
      return not_found unless current_user.privilege?('flag_curate') && !@comment_thread.locked?

      lu = nil
      unless params[:duration].blank?
        lu = params[:duration].to_i.days.from_now
      end
      @comment_thread.update(locked: true, locked_by: current_user, locked_until: lu)

      redirect_to comment_thread_path(@comment_thread.id)
      return
    when 'archive'
      return not_found unless current_user.privilege?('flag_curate') && !@comment_thread.archived?

      @comment_thread.update(archived: true, archived_by: current_user)
    when 'delete'
      return not_found unless current_user.privilege?('flag_curate') && !@comment_thread.deleted?

      @comment_thread.update(deleted: true, deleted_by: current_user)
    when 'follow'
      ThreadFollower.create comment_thread: @comment_thread, user: current_user
    else
      return not_found
    end

    render json: { status: 'success' }
  end

  def thread_unrestrict
    case params[:type]
    when 'lock'
      return not_found unless current_user.privilege?('flag_curate') && @comment_thread.locked?

      @comment_thread.update(locked: false, locked_by: nil, locked_until: nil)
    when 'archive'
      return not_found unless current_user.privilege?('flag_curate') && @comment_thread.archived?

      @comment_thread.update(archived: false, archived_by: nil, ever_archived_before: true)
    when 'delete'
      return not_found unless current_user.privilege?('flag_curate') && @comment_thread.deleted?

      if @comment_thread.deleted_by.is_moderator && !current_user.is_moderator
        render json: { status: 'error',
                       message: 'Threads deleted by a moderator can only be undeleted by a moderator.' }
        return
      end
      @comment_thread.update(deleted: false, deleted_by: nil)
    when 'follow'
      tf = ThreadFollower.find_by(comment_thread: @comment_thread, user: current_user)
      tf&.destroy
    else
      return not_found
    end

    render json: { status: 'success' }
  end

  def post
    @post = Post.find(params[:post_id])
    @comment_threads = if helpers.moderator? || current_user&.has_post_privilege?('flag_curate', @post)
                         CommentThread
                       else
                         CommentThread.undeleted
                       end.where(post: @post).order(deleted: :asc, archived: :asc, reply_count: :desc)
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @comment_threads }
    end
  end

  def pingable
    thread = params[:id] == '-1' ? CommentThread.new(post_id: params[:post]) : CommentThread.find(params[:id])
    ids = helpers.get_pingable(thread)
    users = User.where(id: ids)
    render json: users.map { |u| [u.username, u.id] }.to_h
  end

  private

  def comment_params
    params.require(:comment).permit(:content, :post_id)
  end

  def set_comment
    @comment = Comment.unscoped.find params[:id]
  end

  def set_thread
    @comment_thread = CommentThread.find(params[:id])
    @post = @comment_thread.post
  end

  def check_privilege
    unless current_user.is_moderator || current_user.is_admin || current_user == @comment.user
      render template: 'errors/forbidden', status: :forbidden
    end
  end

  def check_if_parent_post_locked
    check_if_locked(@comment.post)
  end

  def check_if_target_post_locked
    check_if_locked(Post.find(params[:post_id]))
  end

  def check_for_pings(thread, content)
    pingable = helpers.get_pingable(thread)
    matches = content.scan(/@#(\d+)/)
    matches.flatten.select { |m| pingable.include?(m.to_i) }.map(&:to_i)
  end

  def apply_pings(pings)
    pings.each do |p|
      user = User.where(id: p).first
      next if user.nil?

      unless user.id == @comment.post.user_id
        user.create_notification("You were mentioned in a comment to #{@comment_thread.title}",
                                 helpers.comment_link(@comment))
      end
    end
  end

  def comment_rate_limited
    recent_comments = Comment.where(created_at: 24.hours.ago..DateTime.now, user: current_user).where \
                             .not(post: Post.includes(:parent).where(parents_posts: { user_id: current_user.id })) \
                             .where.not(post: Post.where(user_id: current_user.id)).count
    max_comments_per_day = SiteSetting[current_user.privilege?('unrestricted') ? 'RL_Comments' : 'RL_NewUserComments']

    if (!@post.user_id == current_user.id || @post&.parent&.user_id == current_user.id) \
       && recent_comments >= max_comments_per_day
      comment_limit_msg = "You have used your daily comment limit of #{recent_comments} comments." \
                          ' Come back tomorrow to continue commenting. Comments on own posts and on answers' \
                          ' to own posts are exempt.'

      if recent_comments.zero? && !current_user.privilege?('unrestricted')
        comment_limit_msg = 'New users can only comment on their own posts and on answers to them.'
      end

      AuditLog.rate_limit_log(event_type: 'comment', related: @comment, user: current_user,
                              comment: "limit: #{max_comments_per_day}\n\comment:\n#{@comment.attributes_print}")

      render json: { status: 'failed', message: comment_limit_msg }, status: :forbidden
      return true
    end
    false
  end
end
