# Represents a comment. Comments are attached to both a post and a user.
class Comment < ActiveRecord::Base
  default_scope { where(is_deleted: false) }

  belongs_to :post, :polymorphic => true
  belongs_to :user
end
