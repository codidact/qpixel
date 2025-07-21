class CommentThread < ApplicationRecord
  include Lockable
  include PostRelated
  include SoftDeletable

  has_many :comments
  has_many :thread_follower
  belongs_to :archived_by, class_name: 'User', optional: true

  scope :initially_visible, -> { where(deleted: false, archived: false).where('reply_count > 0') }
  scope :publicly_available, -> { where(deleted: false).where('reply_count > 0') }
  scope :archived, -> { where(archived: true) }

  after_create :create_follower

  def read_only?
    locked? || archived? || deleted?
  end

  def followed_by?(user)
    ThreadFollower.where(comment_thread: self, user: user).any?
  end

  def can_access?(user)
    (!deleted? || user&.privilege?('flag_curate') || user&.post_privilege?('flag_curate', post)) &&
      post.can_access?(user)
  end

  def self.post_followed?(post, user)
    ThreadFollower.where(post: post, user: user).any?
  end

  private

  # Comment author and post author are automatically followed to the thread. Question author is NOT
  # automatically followed on new answer comment threads. Comment author follower creation is done
  # on the Comment model.
  def create_follower
    if post.user.preference('auto_follow_comment_threads') == 'true'
      ThreadFollower.create comment_thread: self, user: post.user
    end
  end
end
