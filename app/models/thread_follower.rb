class ThreadFollower < ApplicationRecord
  belongs_to :comment_thread
  belongs_to :user

  after_create :bump_thread_last_activity
  before_destroy :bump_thread_last_activity

  private

  def bump_thread_last_activity
    comment_thread&.bump_last_activity(persist_changes: true)
  end
end
