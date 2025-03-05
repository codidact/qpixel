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

  validate :maximum_title_length
  validates :title, presence: { message: I18n.t('comments.errors.title_presence') }

  after_create :create_follower

  # Are there any threads on a given post that a given user follows?
  # @param post [Post] post to check
  # @param user [User] user to check
  # @return [Boolean] check result
  def self.post_followed?(post, user)
    ThreadFollower.where(post: post, user: user).any?
  end

  # Is the thread read-only (can't be edited)?
  # @return [Boolean] check result
  def read_only?
    locked? || archived? || deleted?
  end

  # Is a given user a follower of the thread?
  # @param user [User] user to check
  # @return [Boolean] check result
  def followed_by?(user)
    ThreadFollower.where(comment_thread: self, user: user).any?
  end

  # Does a given user have access to the thread?
  # @param user [User] user to check access for
  # @return [Boolean] check result
  def can_access?(user)
    (!deleted? || user&.privilege?('flag_curate') || user&.post_privilege?('flag_curate', post)) &&
      post.can_access?(user)
  end
<<<<<<< HEAD

  # Gets a list of user IDs who should be pingable in the thread.
  # @return [Array<Integer>]
  def pingable
    # post author +
    # answer authors +
    # last 500 history event users +
    # last 500 comment authors +
    # all thread followers
    query = <<~END_SQL
      SELECT posts.user_id FROM posts WHERE posts.id = #{post.id}
      UNION DISTINCT
      SELECT DISTINCT posts.user_id FROM posts WHERE posts.parent_id = #{post.id}
      UNION DISTINCT
      SELECT DISTINCT ph.user_id FROM post_histories ph WHERE ph.post_id = #{post.id}
      UNION DISTINCT
      SELECT DISTINCT comments.user_id FROM comments WHERE comments.post_id = #{post.id}
      UNION DISTINCT
      SELECT DISTINCT tf.user_id FROM thread_followers tf WHERE tf.comment_thread_id = #{id || '-1'}
    END_SQL

    ActiveRecord::Base.connection.execute(query).to_a.flatten
  end

  def maximum_title_length
    max_len = SiteSetting['MaxThreadTitleLength'] || 255
    if title.length > [max_len, 255].min
      errors.add(:title, "can't be more than #{max_len} characters")
    end
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
=======
>>>>>>> 2dc90352 (Move followed_by? method to post model to simplify calling)
end
