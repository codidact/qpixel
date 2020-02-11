# Represents a comment. Comments are attached to both a post and a user.
class Comment < ApplicationRecord
  include PostRelated

  scope :deleted, -> { where(deleted: true) }
  scope :undeleted, -> { where(deleted: false) }

  belongs_to :user
  has_one :parent_question, through: :post, source: :parent, class_name: 'Question'

  validates :content, length: {minimum: 15, maximum: 500}

  def root
    # If parent_question is nil, the comment is already on a question, so we can just return post.
    parent_question || post
  end
end
