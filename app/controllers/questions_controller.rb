# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  before_action :authenticate_user!, :only => [:new, :create, :edit, :update, :destroy, :undelete]
  before_action :set_question, :only => [:show, :edit, :update, :destroy, :undelete]

  # Web action. Retrieves a paginated list of all the questions currently in the database for use by the view.
  def index
    @questions = Question.all.order('created_at DESC').paginate(:page => params[:page], :per_page => 50)
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
    check_your_privilege('Edit', @question)
  end

  # Authenticated web action. Based on the information submitted from the <tt>edit</tt> view, updates the question.
  # In a similar fashion to <tt>create</tt>, updates the tags explicitly because the standard <tt>update</tt> call
  # can't be relied on.
  def update
    check_your_privilege('Edit', @question)
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

  # Authenticated web action. Marks the question as 'deleted' - that is, sets the <tt>is_deleted</tt> field to true.
  def destroy
    check_your_privilege('Delete', @question)
    @question.is_deleted = true
    @question.deleted_at = DateTime.now
    calculate_reputation(@question.user, @question, -1)
    if @question.save
      redirect_to url_for(:controller => :questions, :action => :show, :id => @question.id)
    else
      flash[:error] = "The question could not be deleted."
      redirect_to url_for(:controller => :questions, :action => :show, :id => @question.id)
    end
  end

  # Authenticated web action. Basically the opposite of <tt>:destroy</tt> - removes the <tt>is_deleted</tt> flag from
  # the question, making it visible from default scope again.
  def undelete
    check_your_privilege('Delete', @question)
    @question.is_deleted = false
    @question.deleted_at = DateTime.now
    calculate_reputation(@question.user, @question, 1)
    if @question.save
      redirect_to url_for(:controller => :questions, :action => :show, :id => @question.id)
    else
      flash[:error] = "The question could not be undeleted."
      redirect_to url_for(:controller => :questions, :action => :show, :id => @question.id)
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
      begin
        @question = Question.find params[:id]
      rescue
        if current_user.has_privilege?('ViewDeleted')
          @question ||= Question.unscoped.find params[:id]
        end
        if @question.nil?
          raise ActionController::RoutingError.new('Not Found')
        end
      end
    end

    # Calculates and changes any reputation changes a user has had from a post. If <tt>direction</tt> is 1, we add the
    # reputation. If it's -1, we take it away.
    def calculate_reputation(user, post, direction)
      upvote_rep = post.votes.where(:vote_type => 1).count * get_setting('QuestionUpVoteRep').to_i
      downvote_rep = post.votes.where(:vote_type => -1).count * get_setting('QuestionDownVoteRep').to_i
      user.reputation += direction * (upvote_rep + downvote_rep)
      user.save!
    end
end
