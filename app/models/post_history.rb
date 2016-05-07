class PostHistory < ActiveRecord::Base
  belongs_to :post_history_type
  belongs_to :user
end
