# Provides mainly web actions for using and making comments.
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:post, :show]
  before_action :set_comment, only: [:update, :destroy, :undelete, :show]
  before_action :check_privilege, only: [:update, :destroy, :undelete]

  def create
    @comment = Comment.new comment_params.merge(user: current_user)
    if @comment.save
      unless @comment.post.user == current_user
        @comment.post.user.create_notification("New comment on #{@comment.root.title}", comment_link(@comment))
      end

      match = @comment.content.match(/@(?<name>\S+) /)
      if match && match[:name]
        user = User.where("LOWER(REPLACE(username, ' ', '')) = LOWER(?)", match[:name]).first
        user&.create_notification('You were mentioned in a comment', comment_link(@comment))
      end

      render json: { status: 'success',
                     comment: render_to_string(partial: 'comments/comment', locals: { comment: @comment }) }
    else
      render json: { status: 'failed', message: @comment.errors.full_messages.join(', ') }, status: 500
    end
  end

  def update
    if @comment.update comment_params
      render json: { status: 'success',
                     comment: render_to_string(partial: 'comments/comment', locals: { comment: @comment }) }
    else
      render json: { status: 'failed',
                     message: "Comment failed to save (#{@comment.errors.full_messages.join(', ')})" }, status: 500
    end
  end

  def destroy
    if @comment.update(deleted: true)
      render json: { status: 'success' }
    else
      render json: { status: 'failed' }, status: 500
    end
  end

  def undelete
    if @comment.update(deleted: false)
      render json: { status: 'success' }
    else
      render json: { status: 'failed' }, status: 500
    end
  end

  def show
    respond_to do |format|
      format.html { render partial: 'comments/comment', locals: { comment: @comment } }
      format.json { render json: @comment }
    end
  end

  def post
    @comments = if current_user&.is_moderator || current_user&.is_admin
                  Comment.all
                else
                  Comment.undeleted
                end.where(post_id: params[:post_id])
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @comments }
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
      render template: 'errors/forbidden', status: 401
    end
  end

  def comment_link(comment)
    if comment.post.question?
      question_path(comment.post, anchor: "comment-#{comment.id}")
    else
      question_path(comment.post.parent, anchor: "comment-#{comment.id}")
    end
  end
end

# Provides a custom HTML sanitization interface to use for cleaning up the HTML in questions.
class CommentScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a b i em strong strike del code]
    self.attributes = %w[href title]
  end

  def skip_node?(node)
    node.text?
  end
end
