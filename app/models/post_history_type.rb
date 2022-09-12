class PostHistoryType < ApplicationRecord
  has_many :post_histories

  validates :name, uniqueness: { case_sensitive: false }
end
