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

  def read_only?
    locked? || archived? || deleted?
  end

  def followed_by?(user)
    ThreadFollower.where(comment_thread: self, user: user).any?
  end

  def can_access?(user)
    (!deleted? || user&.privilege?('flag_curate') || user&.has_post_privilege?('flag_curate', post)) &&
      post.can_access?(user)
  end
end
