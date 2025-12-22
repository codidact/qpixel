class ThreadFollower < ApplicationRecord
  belongs_to :comment_thread, optional: true
  belongs_to :post, optional: true
  belongs_to :user

  after_create :bump_thread_last_activity_at
  before_destroy :bump_thread_last_activity_at

  validate :thread_or_post

  private

  def bump_thread_last_activity_at
    comment_thread&.bump_last_activity_at
    comment_thread&.save
  end

  def thread_or_post
    if comment_thread.nil? && post.nil?
      errors.add(:base, 'Must refer to either a comment thread or a post.')
    end
  end
end
