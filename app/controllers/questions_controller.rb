# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :undelete, :close, :reopen]
  before_action :set_question, only: [:show, :edit, :update, :destroy, :undelete, :close, :reopen]
  @@markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new, extensions = {})

  def self.renderer
    @@markdown_renderer
  end

  def index
    @questions = Question.undeleted.order('updated_at DESC').paginate(page: params[:page], per_page: 25)
  end

  def show
    if @question.deleted?
      check_your_privilege('ViewDeleted', @question) or return
    end
    @votes = @question.votes.group(:vote_type).count(:vote_type)
    @answers = if current_user&.has_privilege?('ViewDeleted')
                 @question.answers
               else
                 @question.answers.undeleted
               end.includes(:votes).order(Arel.sql('score DESC'))
  end

  def tagged
    @tag = Tag.find_by_name params[:tag]
    @questions = @tag.posts.order('updated_at DESC').paginate(page: params[:page], per_page: 50)
  end

  def new
    @question = Question.new
  end

  def create
    params[:question][:tags] = params[:question][:tags].split(" ")
    @question = Question.new(question_params.merge(tags_cache: params[:question][:tags], user: current_user, score: 0,
                                                   body: QuestionsController.renderer.render(params[:question][:body_markdown])))
    if @question.save
      redirect_to url_for(controller: :questions, action: :show, id: @question.id)
    else
      render :new, status: 400
    end
  end

  def edit
    return unless check_your_privilege('Edit', @question)
  end

  def update
    return unless check_your_privilege('Edit', @question)
    params[:question][:tags] = params[:question][:tags].split(" ")
    if @question.update(question_params.merge(tags_cache: params[:question][:tags],
                                              body: QuestionsController.renderer.render(params[:question][:body_markdown])))
      PostHistory.post_edited(@question, current_user)
      redirect_to url_for(controller: :questions, action: :show, id: @question.id)
    else
      render :edit
    end
  end

  def destroy
    unless check_your_privilege('Delete', @question, false)
      flash[:danger] = 'You must have the Delete privilege to delete questions.'
      redirect_to question_path(@question) and return
    end

    if @question.deleted
      flash[:danger] = "Can't delete a deleted question."
      redirect_to question_path(@question) and return
    end

    if @question.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user)
      PostHistory.post_deleted(@question, current_user)
      redirect_to url_for(controller: :questions, action: :show, id: @question.id)
    else
      flash[:danger] = "Can't delete this question right now. Try again later."
      redirect_to url_for(controller: :questions, action: :show, id: @question.id)
    end
  end

  def undelete
    unless check_your_privilege('Delete', @question, false)
      flash[:danger] = "You must have the Delete privilege to undelete questions."
      redirect_to question_path(@question) and return
    end

    unless @question.deleted
      flash[:danger] = "Can't undelete an undeleted question."
      redirect_to question_path(@question) and return
    end

    if @question.update(deleted: false, deleted_at: nil, deleted_by: nil)
      PostHistory.post_undeleted(@question, current_user)
      redirect_to url_for(controller: :questions, action: :show, id: @question.id)
    else
      flash[:danger] = "Can't undelete this question right now. Try again later."
      redirect_to url_for(controller: :questions, action: :show, id: @question.id)
    end
  end

  def feed
    @questions = Rails.cache.fetch("questions_rss", expires_in: 5.minutes) do
      Question.all.order(created_at: :desc).limit(25)
    end
    respond_to do |format|
      format.rss { render layout: false }
    end
  end

  def close
    unless check_your_privilege('Close', nil, false)
      flash[:danger] = 'You must have the Close privilege to close questions.'
      redirect_to question_path(@question) and return
    end

    if @question.closed
      flash[:danger] = 'Cannot close a closed question.'
      redirect_to question_path(@question) and return
    end

    if @question.update(closed: true, closed_by: current_user, closed_at: Time.now)
      PostHistory.question_closed(@question, current_user)
    else
      flash[:danger] = "Can't close this question right now. Try again later."
    end
    redirect_to question_path(@question)
  end

  def reopen
    unless check_your_privilege('Close', nil, false)
      flash[:danger] = 'You must have the Close privilege to reopen questions.'
      redirect_to question_path(@question) and return
    end

    unless @question.closed
      flash[:danger] = 'Cannot reopen an open question.'
      redirect_to question_path(@question) and return
    end

    if @question.update(closed: false, closed_by: current_user, closed_at: Time.now)
      PostHistory.question_reopened(@question, current_user)
    else
      flash[:danger] = "Can't reopen this question right now. Try again later."
    end
    redirect_to question_path(@question)
  end

  private

  def question_params
    params.require(:question).permit(:body_markdown, :title, :tags)
  end

  def set_question
    begin
      @question = Question.find params[:id]
    rescue
      if current_user.has_privilege?('ViewDeleted')
        @question ||= Question.unscoped.find params[:id]
      end
      if @question.nil?
        render template: 'errors/not_found', status: 404
      end
    end
  end
end