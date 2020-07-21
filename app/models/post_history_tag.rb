class PostHistoryTag < ApplicationRecord
  belongs_to :post_history
  belongs_to :tag

  validates :relationship, uniqueness: { scope: [:tag_id, :post_history_id] }
end
