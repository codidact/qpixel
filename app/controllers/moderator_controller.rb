# Web controller. Provides authenticated actions for use by moderators. A lot of the stuff in here, and hence a lot of
# the tools, are rather repetitive.
class ModeratorController < ApplicationController
  # Administrative web action. No dynamic content - this is purely representative of the existence of a (relatively)
  # static view for this path.
  def index
  end

  # Administrative web action. Gets a list of recently deleted questions so that moderators can review deletions.
  def recently_deleted_questions
    @questions = Question.unscoped.where(:is_deleted => true).order('deleted_at DESC').paginate(:page => params[:page], :per_page => 50)
  end

  # Administrative web action. Gets a list of recently deleted answers so that moderators can review deletions.
  def recently_deleted_answers
    @answers = Answer.where(:is_deleted => true).order('deleted_at DESC').paginate(:page => params[:page], :per_page => 50)
  end

  # Administrative web action. Gets a list of recently undeleted questions so that moderators can review undeletions.
  def recently_undeleted_questions
    @questions = Question.unscoped.where(:is_deleted => false, :deleted_at => 'is not null').paginate(:page => params[:page], :per_page => 50)
  end

  # Administrative web action. Gets a list of recently undeleted answers so that moderators can review undeletions.
  def recently_undeleted_answers
    @answers = Answer.where(:is_deleted => false, :deleted_at => 'is not null').paginate(:page => params[:page], :per_page => 50)
  end
end
