# Web controller. Provides actions that relate to answers. Pretty much the standard set of resources, really - it's
# questions that have a few more actions.
class AnswersController < ApplicationController
  before_action :authenticate_user!, :only => [:new, :create]

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
    if @answer.save
      redirect_to url_for(:controller => :questions, :action => :show, :id => params[:id])
    else
      render :new
    end
  end

  private
    # Sanitized parameters for use by question operations. All we need to let through here is the answer body - the user
    # shouldn't be able to supply any other information.
    def answer_params
      params.require(:answer).permit(:body)
    end
end
