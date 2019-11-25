# Web controller. Provides authenticated actions for use by moderators. A lot of the stuff in here, and hence a lot of
# the tools, are rather repetitive.
class ModeratorController < ApplicationController
  before_action :verify_moderator

  def index
  end

  def recently_deleted_questions
    @questions = Question.unscoped.where(deleted: true).order('deleted_at DESC').paginate(page: params[:page], per_page: 50)
  end

  def recently_deleted_answers
    @answers = Answer.where(deleted: true).order('deleted_at DESC').paginate(page: params[:page], per_page: 50)
  end

  def recently_undeleted_questions
    @questions = Question.unscoped.where(deleted: false).where.not(deleted_at: nil).paginate(page: params[:page], per_page: 50)
  end

  def recently_undeleted_answers
    @answers = Answer.where(deleted: false).where.not(deleted_at: nil).paginate(page: params[:page], per_page: 50)
  end
end
