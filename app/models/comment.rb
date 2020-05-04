# Represents a comment. Comments are attached to both a post and a user.
class Comment < ApplicationRecord
  include PostRelated

  scope :deleted, -> { where(deleted: true) }
  scope :undeleted, -> { where(deleted: false) }

  belongs_to :user
  has_one :parent_question, through: :post, source: :parent, class_name: 'Question'

  validate :content_length

  def root
    # If parent_question is nil, the comment is already on a question, so we can just return post.
    parent_question || post
  end

  def content_length
    stripped = content.strip.tr "\r", ''
    if stripped.size < 15
      errors.add(:content, 'is too short (minimum is 15 characters)')
    elsif stripped.size > 500
      errors.add(:content, 'is too long (maximum is 500 characters)')
    end
  end
end
