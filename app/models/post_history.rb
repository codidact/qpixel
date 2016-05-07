class PostHistory < ActiveRecord::Base
  has_one :post_history_type
  has_one :user
  belongs_to :post, :polymorphic => true
end
