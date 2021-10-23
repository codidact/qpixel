# Web controller. Provides actions that relate to answers. Pretty much the standard set of resources, really - it's
# questions that have a few more actions.
class AnswersController < ApplicationController
  before_action :authenticate_user!, only: [:convert_to_comment]
  before_action :set_answer, only: [:convert_to_comment]
  before_action :check_if_answer_locked, only: [:convert_to_comment]

  def convert_to_comment
    return not_found unless current_user.has_post_privilege?('flag_curate', @answer)

    text = @answer.body_markdown
    comments = helpers.split_words_max_length(text, 500)
    post = Post.find(params[:post_id])
    thread = post.comment_threads.find_or_create_by(title: 'General comments', deleted: false)
    created = nil
    ActiveRecord::Base.transaction do
      created = comments.map do |c|
        Comment.create!(user: @answer.user, post: post, comment_thread: thread, community: @answer.community,
                        content: c)
      end
      @answer.update!(deleted: true, deleted_at: DateTime.now, deleted_by: current_user)
      AuditLog.moderator_audit(event_type: 'convert_to_comment', related: @answer, user: current_user,
                               comment: created.map(&:id).join(', '))
    end
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
