# Provides mainly web actions for using and making comments.
class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: [:update, :destroy, :undelete]
  before_action :check_privilege, only: [:update, :destroy, :undelete]
  @@markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new, extensions = {})

  def self.renderer
    @@markdown_renderer
  end

  def create
    @comment = Comment.new comment_params.merge(user: current_user)
    root_id = @comment.root.id
    if @comment.save
      @comment.post.user.create_notification("New comment on #{(@comment.root.title)}", "/questions/#{root_id}")

      match = @comment.content.match(/@(?<name>\S+) /)
      if match && match[:name]
        user = User.find_by_username(match[:name])
        user.create_notification("You were mentioned in a comment", "/questions/#{root_id}") if user
      end
    else
      flash[:error] = "Comment failed to save."
    end
    redirect_to url_for(controller: :questions, action: :show, id: root_id)
  end

  def update
    unless @comment.update comment_params
      flash[:error] = "Comment failed to update."
    end
    redirect_to url_for(controller: :questions, action: :show, id: @comment.root.id)
  end

  def destroy
    @comment.deleted = true
    unless @comment.save
      flash[:error] = "Comment marked deleted, but not saved - status unknown."
    end
    redirect_to url_for(controller: :questions, action: :show, id: @comment.root.id)
  end

  def undelete
    @comment.deleted = false
    unless @comment.save
      flash[:error] = "Comment marked undeleted, but not saved - status unknown."
    end
    redirect_to url_for(controller: :questions, action: :show, id: @comment.root.id)
  end

  private

  def comment_params
    params.require(:comment).permit(:content, :post_type, :post_id)
  end

  def set_comment
    @comment = Comment.unscoped.find params[:id]
  end

  def check_privilege
    unless current_user.is_moderator || current_user.is_admin || current_user == @comment.user
      render template: 'errors/forbidden', status: 401
    end
  end
end

# Provides a custom HTML sanitization interface to use for cleaning up the HTML in questions.
class CommentScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w( a b i em strong strike del code )
    self.attributes = %w( href title )
  end

  def skip_node?(node)
    node.text?
  end
end
