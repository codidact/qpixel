class PostHistory < ActiveRecord::Base
  has_one :post_history_type
  belongs_to :user
end
