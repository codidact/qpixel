class CommentThread < ApplicationRecord
  include PostRelated

  has_many :comments
  has_many :thread_follower
  belongs_to :locked_by, class_name: 'User', optional: true
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true

  scope :undeleted, -> { where(deleted: false) }
  scope :publicly_available, -> { where(deleted: false, archived: false).where('reply_count > 0') }

  after_create :create_followers

  def read_only?
    locked? || archived? || deleted?
  end

  def locked?
    locked && (locked_until.nil? || locked_until > DateTime.now)
  end

  def followed_by?(user)
    ThreadFollower.where(comment_thread: self, user: user).any?
  end

  def can_access?(user)
    (!deleted? || user&.privilege?('flag_curate')) && post.can_access?(user)
  end

  private

  # Comment author and post author are automatically followed to the thread. Question author is NOT
  # automatically followed on new answer comment threads.
  def create_followers
    ThreadFollower.create comment_thread: self, user: user
    ThreadFollower.create comment_thread: self, user: post.user
  end
end