# Represents a comment. Comments are attached to both a post and a user.
class Comment < ActiveRecord::Base
  default_scope { where(deleted: false) }

  belongs_to :post
  belongs_to :user

  validates :content, length: { minimum: 15, maximum: 500 }
end
