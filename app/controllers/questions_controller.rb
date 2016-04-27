# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  before_action :authenticate_user!, :only => [:new, :create]

  # Web action. Retrieves a paginated list of all the questions currently in the database for use by the view.
  def index
    @questions = Question.all.paginate(:page => params[:page], :per_page => 50)
  end

  # Web action. Retrieves a single question, specified by the query string parameter <tt>id</tt>.
  def show
    @question = Question.find params[:id]
  end

  # Web action. Retrieves a paginated list of all questions where the tags contain a tag specified in the query string
  # parameter <tt>tag</tt>.
  def tagged
    @questions = Question.where('tags like ?', "%#{params[:tag]}%").paginate(:page => params[:page], :per_page => 50)
  end

  # Authenticated web action. Creates a new question as a resource for form creation in the view.
  def new
    @question = Question.new
  end

  # Authenticated web action. Based on data submitted from the <tt>new</tt> view, creates a new question. Explicitly
  # assigns tags to the question rather than relying on <tt>Question.create</tt> because the latter doesn't always work.
  # Also applies a default score and assigns the question to the currently signed in user.
  # Will redirect on completion; to the question page on success, or back to the <tt>new</tt> action on error.
  def create
    params[:question][:tags] = params[:question][:tags].split(" ")
    @question = Question.new question_params
    @question.tags = params[:question][:tags]
    @question.user = current_user
    @question.score = 0
    if @question.save
      redirect_to url_for(:controller => :questions, :action => :show, :id => @question.id)
    else
      flash[:error] = "Your question could not be posted - please try again."
      redirect_to url_for(:controller => :questions, :action => :new)
    end
  end

  private
    # Sanitizes parameters for use by <tt>Question.create</tt> or <tt>Question.update</tt>. The only attributes that
    # users should be able to submit are <tt>:body</tt>, <tt>:title</tt>, and <tt>:tags</tt>; any other attributes
    # can either be inferred or defaulted to correct values.
    def question_params
      params.require(:question).permit(:body, :title, :tags)
    end
end
