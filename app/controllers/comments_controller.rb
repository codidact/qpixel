# Provides mainly API actions for using and making comments.
class CommentsController < ApplicationController
  before_action :auth_for_commenting

  # Authenticated API action. Creates a comment based on the data passed.
  def create
    @comment = Comment.new comment_params
    if @comment.save
      render :json => { :status => 'success' }, :status => 201
    else
      render :json => { :status => 'failed', :message => 'Comment failed to save.' }, :status => 500
    end
  end

  private
    # Ensures users are authenticated before being able to comment. This doesn't use the standard
    # <tt>:authenticate_user!</tt> because that redirects if the user isn't logged in, which isn't the behaviour we
    # want for comments.
    def auth_for_commenting
      unless user_logged_in?
        render :json => { :status => 'failed', :message => 'You must be logged in to comment.' }, :status => 403
        return
      end
    end

    # Sanitizes parameters for use in creating or updating comments.
    def comment_params
      params.require(:comment).permit(:content)
    end
end
