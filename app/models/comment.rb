# Represents a comment. Comments are attached to both a post and a user.
class Comment < ActiveRecord::Base
  belongs_to :post, :polymorphic => true
  belongs_to :user
end
