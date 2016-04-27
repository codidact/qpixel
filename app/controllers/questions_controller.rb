# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  before_action :authenticate_user!, :only => [:new, :create]
  before_action :set_question, :only => [:show, :edit, :update]
  before_action(only: [:edit, :update]) { check_your_post_privilege(@question, 'Edit') }

  # Web action. Retrieves a paginated list of all the questions currently in the database for use by the view.
  def index
    @questions = Question.all.paginate(:page => params[:page], :per_page => 50)
  end

  # Web action. Retrieves a single question, specified by the query string parameter <tt>id</tt>.
  def show
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
      render :new
    end
  end

  # Authenticated web action. Retrieves a single question for editing. Permission to perform this action is based on
  # three conditions: either (a) the editing user is the OP; (b) the editing user is a mod or admin; or (c) the editing
  # user has is at or over the editing privilege threshold (the <tt>EditPrivilegeThreshold</tt> setting.)
  def edit
  end

  def update
    params[:question][:tags] = params[:question][:tags].split(" ")
    if @question.update question_params
      @question.tags = params[:question][:tags]
      if @question.save
        redirect_to url_for(:controller => :questions, :action => :show, :id => @question.id)
      else
        render :edit
      end
    else
      render :edit
    end
  end

  private
    # Sanitizes parameters for use by <tt>Question.create</tt> or <tt>Question.update</tt>. The only attributes that
    # users should be able to submit are <tt>:body</tt>, <tt>:title</tt>, and <tt>:tags</tt>; any other attributes
    # can either be inferred or defaulted to correct values.
    def question_params
      params.require(:question).permit(:body, :title, :tags)
    end

    # Retrives the question identified by the query string parameter <tt>id</tt>.
    def set_question
      @question = Question.find params[:id]
    end
end
