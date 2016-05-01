# Provides mainly API actions for using and making comments.
class CommentsController < ApplicationController
  before_action :auth_for_commenting
  before_action :set_comment, :only => [:update, :destroy, :undelete]

  # Authenticated API action. Creates a comment based on the data passed.
  def create
    @comment = Comment.new comment_params
    post = params[:post_type] == 'Question' ? Question.find(params[:post_id]) : Answer.find(params[:post_id])
    @comment.post = post
    @comment.user = current_user
    if @comment.save
      render :json => { :status => 'success' }, :status => 201
    else
      render :json => { :status => 'failed', :message => 'Comment failed to save.' }, :status => 500
    end
  end

  # Authenticated API action. Updates an existing comment with new data, based on the parameters passed to the request.
  def update
    if @comment.update comment_params
      render :json => { :status => 'success' }
    else
      render :json => { :status => 'failed', :message => 'Comment failed to update.' }, :status => 500
    end
  end

  # Authenticated API action. Deletes a comment by setting the <tt>is_deleted</tt> field to true.
  def destroy
    @comment.is_deleted = true
    if @comment.save
      render :json => { :status => 'success' }
    else
      render :json => { :status => 'failed', :message => 'Comment marked deleted, but unsaved - status unknown.' }, :status => 500
    end
  end

  # Authenticated API action. Undeletes a comment by returning the <tt>is_deleted</tt> field to false.
  def undelete
    @comment.is_deleted = false
    if @comment.save
      render :json => { :status => 'success' }
    else
      render :json => { :status => 'failed', :message => 'Comment undeleted, but unsaved - status unknown.' }, :status => 500
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

    # Finds the comment with the given ID and sets it to the <tt>@comment</tt> variable.
    def set_comment
      @comment = Comment.find params[:id]
    end
end
