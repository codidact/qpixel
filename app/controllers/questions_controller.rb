# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :new_meta, :create, :edit, :update, :destroy, :undelete,
                                            :close, :reopen]
  before_action :set_question, only: [:show, :edit, :update, :destroy, :undelete, :close, :reopen]

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
                       .or(Answer.where(parent_id: @question.id, user_id: current_user&.id))
               end.user_sort({ term: params[:sort], default: Arel.sql('deleted ASC, score DESC, RAND()') },
                             score: Arel.sql('deleted ASC, score DESC, RAND()'), age: :created_at)
               .paginate(page: params[:page], per_page: 20)
               .includes(:votes, :user, :comments, :license)

    @close_reasons = CloseReason.active
  end

  def tagged
    @tag = Tag.find_by name: params[:tag], tag_set_id: params[:tag_set]
    if @tag.nil?
      not_found
      return
    end
    @questions = @tag.posts.list_includes.undeleted.order('updated_at DESC').paginate(page: params[:page], per_page: 50)
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

  def edit; end

  def update
    can_post_in_category = @question.category.present? &&
                           (@question.category.min_trust_level || -1) <= current_user&.trust_level
    unless current_user&.has_post_privilege?('Edit', @question) && can_post_in_category
      return update_as_suggested_edit
    end

    tags_cache = params[:question][:tags_cache]&.reject { |e| e.to_s.empty? }
    after_tags = Tag.where(tag_set_id: @question.category.tag_set_id, name: tags_cache)

    if @question.tags == after_tags && @question.body_markdown == params[:question][:body_markdown] &&
       @question.title == params[:question][:title]
      flash[:danger] = "No changes were saved because you didn't edit the post."
      return redirect_to question_path(@question)
    end

    body_rendered = helpers.post_markdown(:question, :body_markdown)
    if @question.update(question_params.merge(tags_cache: tags_cache, body: body_rendered,
                                              last_activity: DateTime.now, last_activity_by: current_user,
                                              last_edited_at: DateTime.now, last_edited_by: current_user))
      PostHistory.post_edited(@question, current_user, before: @question.body_markdown,
                              after: params[:question][:body_markdown], comment: params[:edit_comment],
                              before_title: @question.title, after_title: params[:question][:title],
                              before_tags: @question.tags, after_tags: after_tags)
      redirect_to share_question_path(@question)
    else
      render :edit
    end
  end

  def update_as_suggested_edit
    body_rendered = helpers.post_markdown(:question, :body_markdown)
    new_tags_cache = params[:question][:tags_cache]&.reject(&:empty?)

    body_markdown = if params[:question][:body_markdown] != @question.body_markdown
                      params[:question][:body_markdown]
                    end

    if @question.tags_cache == new_tags_cache && @question.body_markdown == params[:question][:body_markdown] &&
       @question.title == params[:question][:title]
      flash[:danger] = "No changes were saved because you didn't edit the post."
      return redirect_to question_path(@question)
    end

    updates = {
      post: @question,
      user: current_user,
      community: @question.community,
      body: body_rendered,
      title: params[:question][:title] != @question.title ? params[:question][:title] : nil,
      tags_cache: new_tags_cache != @question.tags_cache ? new_tags_cache : @question.tags_cache,
      body_markdown: body_markdown,
      comment: params[:edit_comment],
      active: true, accepted: false,
      decided_at: nil, decided_by: nil,
      rejected_comment: nil
    }

    @edit = SuggestedEdit.new(updates)
    if @edit.save
      @question.user.create_notification("Edit suggested on your post #{@question.title.truncate(50)}",
                                         question_url(@question))
      redirect_to share_question_path(@question)
    else
      @post.errors = @edit.errors
      render :edit
    end
  end

  def destroy
    unless check_your_privilege('Delete', @question, false)
      flash[:danger] = 'You must have the Delete privilege to delete questions.'
      redirect_to(question_path(@question)) && return
    end

    if @question.answer_count.positive? && @question.answers.any? { |a| a.score >= 0.5 }
      flash[:danger] = 'This question cannot be deleted because it has answers.'
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

    if @question.deleted_by.is_moderator && !current_user.is_moderator
      flash[:danger] = 'You cannot undelete this post deleted by a moderator.'
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
    if current_user&.has_privilege?('ViewDeleted')
      @question ||= Question.unscoped.find params[:id]
    end
    if @question.nil?
      not_found
      return
    end
    unless @question.post_type_id == Question.post_type_id
      not_found
    end
  end
end
