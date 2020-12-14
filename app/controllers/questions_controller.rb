# Web controller. Provides actions that relate to questions - this is essentially the standard set of resources, plus a
# couple for the extra question lists (such as listing by tag).
class QuestionsController < ApplicationController
  before_action :authenticate_user!, only: [:destroy, :undelete, :close, :reopen]
  before_action :set_question, only: [:destroy, :undelete, :close, :reopen]
  before_action :check_if_question_locked, only: [:destroy, :undelete, :close, :reopen]

  def lottery
    ids = Rails.cache.fetch 'lottery_questions', expires_in: 24.hours do
      # noinspection RailsParamDefResolve
      Question.main.undeleted.order([Arel.sql('(RAND() - ? * DATEDIFF(CURRENT_TIMESTAMP, posts.created_at)) DESC'),
                                     SiteSetting['LotteryAgeDeprecationSpeed']])
              .limit(25).select(:id).pluck(:id).to_a
    end
    @questions = Question.list_includes.where(id: ids).paginate(page: params[:page], per_page: 25)
  end

  def feed
    @questions = Rails.cache.fetch('questions_rss', expires_in: 5.minutes) do
      Question.all.order(created_at: :desc).limit(25)
    end
    respond_to do |format|
      format.rss { render layout: false }
    end
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
