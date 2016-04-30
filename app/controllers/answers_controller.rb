# Web controller. Provides actions that relate to answers. Pretty much the standard set of resources, really - it's
# questions that have a few more actions.
class AnswersController < ApplicationController
  before_action :authenticate_user!, :only => [:new, :create, :edit, :update, :destroy, :undelete]
  before_action :set_answer, :only => [:edit, :update, :destroy, :undelete]

  # Authenticated web action. Creates a new answer as a resource for form creation in the view.
  def new
    @answer = Answer.new
    @question = Question.find params[:id]
  end

  # Authenticated web action. Based on the data submitted from the <tt>new</tt> view, creates a new answer. Assumes
  # that the route to this action contains the question id, and uses that to assign the answer to a question.
  def create
    @answer = Answer.new answer_params
    @question = Question.find params[:id]
    @answer.question = @question
    @answer.user = current_user
    @answer.score = 0
    @question.user.create_notification("New answer to your question '#{@question.title.truncate(50)}'", "/questions/#{@question.id}")
    if @answer.save
      redirect_to url_for(:controller => :questions, :action => :show, :id => params[:id])
    else
      render :new
    end
  end

  # Authenticated web action. Retrieves a single answer for editing.
  def edit
    check_your_privilege('Edit')
  end

  # Authenticated web aciton. Based on the information given in <tt>:edit</tt>, updates the answer.
  def update
    check_your_privilege('Edit')
    if @answer.update answer_params
      redirect_to url_for(:controller => :questions, :action => :show, :id => @answer.question.id)
    else
      render :edit
    end
  end

  # Authenticated web action. Deletes an answer - that is, applies the <tt>is_deleted</tt> attribute to it.
  def destroy
    check_your_privilege('Delete')
    @answer.is_deleted = true
    @answer.deleted_at = DateTime.now
    calculate_reputation(@answer.user, @answer, -1)
    if @answer.save
      redirect_to url_for(:controller => :questions, :action => :show, :id => @answer.question.id)
    else
      flash[:error] = "The answer could not be deleted."
      redirect_to url_for(:controller => :questions, :action => :show, :id => @answer.question.id)
    end
  end

  # Authenticated web action. Removes the <tt>is_deleted</tt> attribute from an answer - that is, undeletes it.
  def undelete
    check_your_privilege('Delete')
    @answer.is_deleted = false
    @answer.deleted_at = DateTime.now
    calculate_reputation(@answer.user, @answer, 1)
    if @answer.save
      redirect_to url_for(:controller => :questions, :action => :show, :id => @answer.question.id)
    else
      flash[:error] = "The answer could not be undeleted."
      redirect_to url_for(:controller => :questions, :action => :show, :id => @answer.question.id)
    end
  end

  private
    # Sanitized parameters for use by question operations. All we need to let through here is the answer body - the user
    # shouldn't be able to supply any other information.
    def answer_params
      params.require(:answer).permit(:body)
    end

    def set_answer
      @answer = Answer.find params[:id]
    end

    # Calculates and changes any reputation changes a user has had from a post. If <tt>direction</tt> is 1, we add the
    # reputation. If it's -1, we take it away.
    def calculate_reputation(user, post, direction)
      upvote_rep = post.votes.where(:vote_type => 1).count * get_setting('AnswerUpVoteRep').to_i
      downvote_rep = post.votes.where(:vote_type => -1).count * get_setting('AnswerDownVoteRep').to_i
      user.reputation += direction * (upvote_rep + downvote_rep)
      user.save!
    end
end
