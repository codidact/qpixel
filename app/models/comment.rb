# Represents a comment. Comments are attached to both a post and a user.
class Comment < ApplicationRecord
  include PostRelated
  include SoftDeletable
  include Timestamped

  scope :by, ->(user) { where(user: user) }

  belongs_to :user
  belongs_to :comment_thread
  belongs_to :references_comment, class_name: 'Comment', optional: true
  has_one :parent_question, through: :post, source: :parent, class_name: 'Question'
  has_many :flags, as: :post, dependent: :destroy

  after_create :create_follower
  after_update :delete_thread

  counter_culture :comment_thread, column_name: proc { |model| model.deleted? ? nil : 'reply_count' }, touch: true

  validate :content_length

  # Gets last activity date and time on the comment
  # @return [DateTime] last activity date and time
  def last_activity_at
    [created_at, updated_at].compact.max
  end

  def root
    # If parent_question is nil, the comment is already on a question, so we can just return post.
    parent_question || post
  end

  def content_length
    stripped = content.strip.tr "\r", ''
    if stripped.size < 15
      errors.add(:content, 'is too short (minimum is 15 characters)')
    elsif stripped.size > 1000
      errors.add(:content, 'is too long (maximum is 1000 characters)')
    end
  end

  def pings
    pingable = thread.pingable
    matches = content.scan(/@#(\d+)/)
    matches.flatten.select { |m| pingable.include?(m.to_i) }.map(&:to_i)
  end

  private

  def create_follower
    if user.preference('auto_follow_comment_threads') == 'true'
      ThreadFollower.find_or_create_by(comment_thread: comment_thread, user: user)
    end
  end

  def delete_thread
    if deleted? && comment_thread.comments.undeleted.none?
      comment_thread.update(deleted: true, deleted_by_id: -1)
    end
  end
end
