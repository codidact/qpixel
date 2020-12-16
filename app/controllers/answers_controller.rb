# Web controller. Provides actions that relate to answers. Pretty much the standard set of resources, really - it's
# questions that have a few more actions.
class AnswersController < ApplicationController
  before_action :authenticate_user!, only: [:convert_to_comment]
  before_action :set_answer, only: [:convert_to_comment]
  before_action :verify_moderator, only: [:convert_to_comment]
  before_action :check_if_answer_locked, only: [:convert_to_comment]

  def convert_to_comment
    text = @answer.body_markdown
    comments = helpers.split_words_max_length(text, 500)
    created = comments.map do |c|
      Comment.create(user: @answer.user, post_id: params[:post_id], community: @answer.community, content: c)
    end
    @answer.update(deleted: true, deleted_at: DateTime.now, deleted_by: current_user)
    AuditLog.moderator_audit(event_type: 'convert_to_comment', related: @answer, user: current_user,
                             comment: created.map(&:id).join(', '))
    render json: { success: true, comments: created.map(&:id) }
  end

  private

  def set_answer
    @answer = Answer.find params[:id]
  end

  def check_if_answer_locked
    check_if_locked(@answer)
  end
end
