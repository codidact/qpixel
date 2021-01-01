# Provides mainly web actions for using and making comments.
class CommentsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_action :authenticate_user!, except: [:post, :show, :thread]
  before_action :set_comment, only: [:update, :destroy, :undelete, :show]
  before_action :check_privilege, only: [:update, :destroy, :undelete]
  before_action :check_if_target_post_locked, only: [:create]
  before_action :check_if_parent_post_locked, only: [:update, :destroy]

  def create_thread
    @post = Post.find(params[:post_id])
    if @post.comments_disabled && !current_user.is_moderator && !current_user.is_admin
      render json: { status: 'failed', message: 'Comments have been disabled on this post.' }, status: :forbidden
      return
    end

    title = params[:title]
    if title.blank? || title.length == 0
      title = truncate(params[:body], length: 100)
    end

    @comment_thread = CommentThread.new(title: title, post: @post, reply_count: 1, locked: false, archived: false, deleted: false)
    @comment = Comment.new(post: @post, content: params[:body], user: current_user, comment_thread: @comment_thread, has_reference: false)

    return if comment_rate_limited
    
    if @comment_thread.save && @comment.save
      unless @comment.post.user == current_user
        @comment.post.user.create_notification("New comment on #{@comment.root.title}", comment_link(@comment))
      end

      match = @comment.content.match(/@(?<name>\S+) /)
      if match && match[:name]
        user = User.where("LOWER(REPLACE(username, ' ', '')) = LOWER(?)", match[:name]).first
        unless user&.id == @comment.post.user_id
          user&.create_notification('You were mentioned in a comment', comment_link(@comment))
        end
      end

      redirect_to helpers.generic_show_link(@post)
    else
      flash[:error] = 'Could not create comment thread:' + (@comment_thread.errors.full_messages + @comment.errors.full_messages).join(', ')
      redirect_to helpers.generic_show_link(@post)
    end
  end

  def create
    @comment_thread = CommentThread.find(params[:id])
    @post = @comment_thread.post
    if @post.comments_disabled && !current_user.is_moderator && !current_user.is_admin
      render json: { status: 'failed', message: 'Comments have been disabled on this post.' }, status: :forbidden
      return
    end

    @comment = Comment.new(post: @post, content: params[:content], user: current_user, comment_thread: @comment_thread, has_reference: false)

    return if comment_rate_limited

    if @comment.save
      @comment_thread.update(reply_count: @comment_thread.comments.undeleted.size)
      unless @comment.post.user == current_user
        @comment.post.user.create_notification("New comment on #{@comment.root.title}", comment_link(@comment))
      end

      match = @comment.content.match(/@(?<name>\S+) /)
      if match && match[:name]
        user = User.where("LOWER(REPLACE(username, ' ', '')) = LOWER(?)", match[:name]).first
        unless user&.id == @comment.post.user_id
          user&.create_notification('You were mentioned in a comment', comment_link(@comment))
        end
      end

      redirect_to comment_thread_path(@comment_thread.id)
    else
      flash[:error] = @comment.errors.full_messages.join(', ')
      redirect_to comment_thread_path(@comment_thread.id)
    end
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
      @comment_thread.update(reply_count: @comment_thread.comments.undeleted.size)
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
      @comment_thread.update(reply_count: @comment_thread.comments.undeleted.size)
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
    @comment_thread = CommentThread.find(params[:id])
    @post = @comment_thread.post
  end

  def thread_rename
    @comment_thread = CommentThread.find(params[:id])
    return forbidden if @comment_thread.read_only? && !current_user.is_moderator

    @comment_thread.update title: params[:title]
    redirect_to comment_thread_path(@comment_thread.id)
  end

  def post
    @comment_threads = if current_user&.is_moderator || current_user&.is_admin
                  CommentThread
                else
                  CommentThread.undeleted
                end.where(post_id: params[:post_id]).order(reply_count: :desc)
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @comment_threads }
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content, :post_id)
  end

  def set_comment
    @comment = Comment.unscoped.find params[:id]
  end

  def check_privilege
    unless current_user.is_moderator || current_user.is_admin || current_user == @comment.user
      render template: 'errors/forbidden', status: :forbidden
    end
  end

  def comment_link(comment)
    if comment.post.parent_id.present?
      post_url(comment.post.parent_id, anchor: "comment-#{comment.id}")
    else
      post_url(comment.post, anchor: "comment-#{comment.id}")
    end
  end

  def check_if_parent_post_locked
    check_if_locked(@comment.post)
  end

  def check_if_target_post_locked
    check_if_locked(Post.find(params[:post_id]))
  end

  def comment_rate_limited
    recent_comments = Comment.where(created_at: 24.hours.ago..DateTime.now, user: current_user).where \
                             .not(post: Post.includes(:parent).where(parents_posts: { user_id: current_user.id })) \
                             .where.not(post: Post.where(user_id: current_user.id)).count
    max_comments_per_day = SiteSetting[current_user.privilege?('unrestricted') ? 'RL_Comments' : 'RL_NewUserComments']

    # Provides mainly web actions for using and making comments.
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
    return false
  end
end
