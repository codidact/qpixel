# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  before_action :authenticate_user!, only: [:destroy, :undelete, :close, :reopen]
  before_action :set_question, only: [:destroy, :undelete, :close, :reopen]
  before_action :check_if_question_locked, only: [:destroy, :undelete, :close, :reopen]

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

  def destroy
    unless check_your_privilege('flag_curate', @question, false)
      flash[:danger] = helpers.ability_err_msg(:flag_curate, 'delete this question')
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
    unless check_your_privilege('flag_curate', @question, false)
      flash[:danger] = helpers.ability_err_msg(:flag_curate, 'undelete this question')
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

  def reopen
    unless check_your_privilege('flag_close', nil, false)
      flash[:danger] = helpers.ability_err_msg(:flag_close, 'reopen this question')
      redirect_to(question_path(@question)) && return
    end

    unless @question.closed
      flash[:danger] = 'Cannot reopen an open question.'
      redirect_to(question_path(@question)) && return
    end

    if @question.update(closed: false, closed_by: current_user, closed_at: Time.zone.now,
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
    if current_user&.privilege?('flag_curate')
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

  def check_if_question_locked
    check_if_locked(@question)
  end
end
