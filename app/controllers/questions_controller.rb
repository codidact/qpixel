# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :new_meta, :create, :edit, :update, :destroy, :undelete,
                                            :close, :reopen]
  before_action :set_question, only: [:show, :edit, :update, :destroy, :undelete, :close, :reopen]
  @@markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)

  def self.renderer
    @@markdown_renderer
  end

  def index
    sort_params = { activity: :last_activity, age: :created_at, score: :score }
    sort_param = sort_params[params[:sort]&.to_sym] || :last_activity
    @questions = Question.list_includes.main.undeleted.order(sort_param => :desc)
                         .paginate(page: params[:page], per_page: 25)
  end

  def meta
    sort_params = { activity: :last_activity, age: :created_at, score: :score }
    sort_param = sort_params[params[:sort]&.to_sym] || :last_activity
    @questions = Question.list_includes.meta.undeleted.order(sort_param => :desc)
                         .paginate(page: params[:page], per_page: 25)
  end

  def show
    if @question.deleted?
      check_your_privilege('ViewDeleted', @question) || return
    end

    @answers = if current_user&.has_privilege?('ViewDeleted')
                 Answer.where(parent_id: @question.id)
               else
                 Answer.where(parent_id: @question.id).undeleted
               end.user_sort({ term: params[:sort], default: :score },
                             score: :score, age: :created_at)
               .paginate(page: params[:page], per_page: 20)
               .includes(:votes, :user, :comments)

    @close_reasons = CloseReason.active
  end

  def tagged
    @tag = Tag.find_by name: params[:tag], tag_set_id: params[:tag_set]
    if @tag.nil?
      not_found
      return
    end
    @questions = @tag.posts.undeleted.order('updated_at DESC').paginate(page: params[:page], per_page: 50)
  end

  def lottery
    ids = Rails.cache.fetch 'lottery_questions', expires_in: 24.hours do
      # noinspection RailsParamDefResolve
      Question.main.undeleted.order([Arel.sql('(RAND() - ? * DATEDIFF(CURRENT_TIMESTAMP, posts.created_at)) DESC'),
                                     SiteSetting['LotteryAgeDeprecationSpeed']])
              .limit(25).select(:id).pluck(:id).to_a
    end
    @questions = Question.list_includes.where(id: ids).paginate(page: params[:page], per_page: 25)
  end

  def new
    @question = Question.new
  end

  def new_meta
    @question = Question.new
  end

  def create
    body_rendered = QuestionsController.renderer.render(params[:question][:body_markdown])
    @category = Category.find_by(name: params[:category])
    unless @category.present?
      errors.add(:base, 'A category is required. If you don\'t have the option to choose one, this may be a bug.')
      render :new, status: 400
      return
    end

    @question = Question.new(question_params.merge(tags_cache: params[:question][:tags_cache]&.reject(&:empty?),
                                                   user: current_user, score: 0, last_activity: DateTime.now,
                                                   last_activity_by: current_user, body: body_rendered,
                                                   category: @category))
    if @question.save
      redirect_to url_for(controller: :questions, action: :show, id: @question.id)
    else
      render :new, status: 400
    end
  end

  def edit
    check_your_privilege('Edit', @question)
  end

  def update
    return unless check_your_privilege('Edit', @question)

    PostHistory.post_edited(@question, current_user, before: @question.body_markdown,
                            after: params[:question][:body_markdown], comment: params[:edit_comment])
    body_rendered = QuestionsController.renderer.render(params[:question][:body_markdown])
    if @question.update(question_params.merge(tags_cache: params[:question][:tags_cache]&.reject(&:empty?),
                                              body: body_rendered, last_activity: DateTime.now,
                                              last_activity_by: current_user))
      redirect_to url_for(controller: :questions, action: :show, id: @question.id)
    else
      render :edit
    end
  end

  def destroy
    unless check_your_privilege('Delete', @question, false)
      flash[:danger] = 'You must have the Delete privilege to delete questions.'
      redirect_to(question_path(@question)) && return
    end

    if @question.deleted
      flash[:danger] = "Can't delete a deleted question."
      redirect_to(question_path(@question)) && return
    end

    if @question.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user,
                        last_activity: DateTime.now, last_activity_by: current_user)
      PostHistory.post_deleted(@question, current_user)
    else
      flash[:danger] = "Can't delete this question right now. Try again later."
    end
    redirect_to url_for(controller: :questions, action: :show, id: @question.id)
  end

  def undelete
    unless check_your_privilege('Delete', @question, false)
      flash[:danger] = 'You must have the Delete privilege to undelete questions.'
      redirect_to(question_path(@question)) && return
    end

    unless @question.deleted
      flash[:danger] = "Can't undelete an undeleted question."
      redirect_to(question_path(@question)) && return
    end

    if @question.update(deleted: false, deleted_at: nil, deleted_by: nil,
                        last_activity: DateTime.now, last_activity_by: current_user)
      PostHistory.post_undeleted(@question, current_user)
    else
      flash[:danger] = "Can't undelete this question right now. Try again later."
    end
    redirect_to url_for(controller: :questions, action: :show, id: @question.id)
  end

  def feed
    @questions = Rails.cache.fetch('questions_rss', expires_in: 5.minutes) do
      Question.all.order(created_at: :desc).limit(25)
    end
    respond_to do |format|
      format.rss { render layout: false }
    end
  end

  def close
    unless check_your_privilege('Close', nil, false)
      render(json: { status: 'failed', message: 'You must have the Close privilege to close questions.' }, status: 403)
      return
    end

    if @question.closed
      render(json: { status: 'failed', message: 'Cannot close a closed question.' }, status: 400)
      return
    end

    reason = CloseReason.find_by id: params[:reason_id]
    if reason.nil?
      render(json: { status: 'failed', message: 'Close reason not found.' }, status: 404)
      return
    end

    if reason.requires_other_post
      unless Question.exists? params[:other_post]
        render(json: { status: 'failed', message: 'Invalid input for other post.' }, status: 400)
        return
      end

      duplicate_of = Question.find(params[:other_post])
    else
      duplicate_of = nil
    end

    if @question.update(closed: true, closed_by: current_user, closed_at: DateTime.now, last_activity: DateTime.now,
                        last_activity_by: current_user, close_reason: reason, duplicate_post: duplicate_of)
      PostHistory.question_closed(@question, current_user)
      render json: { status: 'success' }
    else
      render json: { status: 'failed', message: "Can't close this question right now. Try again later.",
                     errors: @question.errors.full_messages }
    end
  end

  def reopen
    unless check_your_privilege('Close', nil, false)
      flash[:danger] = 'You must have the Close privilege to reopen questions.'
      redirect_to(question_path(@question)) && return
    end

    unless @question.closed
      flash[:danger] = 'Cannot reopen an open question.'
      redirect_to(question_path(@question)) && return
    end

    if @question.update(closed: false, closed_by: current_user, closed_at: Time.now,
                        last_activity: DateTime.now, last_activity_by: current_user,
                        close_reason: nil, duplicate_post: nil)
      PostHistory.question_reopened(@question, current_user)
    else
      flash[:danger] = "Can't reopen this question right now. Try again later."
    end
    redirect_to question_path(@question)
  end

  private

  def question_params
    params.require(:question).permit(:body_markdown, :title, :tags_cache)
  end

  def set_question
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
