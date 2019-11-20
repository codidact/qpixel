class PostHistoryType < ApplicationRecord
  has_many :post_histories

  validates :name, uniqueness: true
end
