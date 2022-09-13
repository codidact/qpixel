class ThreadFollower < ApplicationRecord
  belongs_to :comment_thread, optional: true
  belongs_to :post, optional: true
  belongs_to :user

  validate :thread_or_post

  private

  def thread_or_post
    if comment_thread.nil? && post.nil?
      errors.add(:base, 'Must refer to either a comment thread or a post.')
    end
  end
end
