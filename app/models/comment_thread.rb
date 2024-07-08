class CommentThread < ApplicationRecord
  include CommunityRelated

  belongs_to :post, optional: true
  has_many :comments
  has_many :thread_follower
  belongs_to :locked_by, class_name: 'User', optional: true
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true

  scope :deleted, -> { where(deleted: true) }
  scope :undeleted, -> { where(deleted: false) }
  scope :initially_visible, -> { where(deleted: false, archived: false, is_private: false).where('reply_count > 0') }
  scope :publicly_available, -> { where(deleted: false, is_private: false).where('reply_count > 0') }
  scope :archived, -> { where(archived: true) }

  after_create :create_follower

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
    (!deleted? || user&.privilege?('flag_curate') || user&.has_post_privilege?('flag_curate', post)) &&
      (!post || post&.can_access?(user)) && (!is_private || followed_by?(user))
  end

  def self.post_followed?(post, user)
    ThreadFollower.where(post: post, user: user).any?
  end

  private

  # Comment author and post author are automatically followed to the thread. Question author is NOT
  # automatically followed on new answer comment threads. Comment author follower creation is done
  # on the Comment model.
  def create_follower
    if post.present? && post.user.preference('auto_follow_comment_threads') == 'true'
      ThreadFollower.create comment_thread: self, user: post.user
    end
  end
end
