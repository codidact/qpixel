class Comment < ActiveRecord::Base
  belongs_to :post, :polymorphic => true
  belongs_to :user
end
