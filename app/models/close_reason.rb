class CloseReason < ApplicationRecord
  include MaybeCommunityRelated

  scope :active, -> { where(active: true) }

  validates :name, presence: true, uniqueness: { scope: [:community_id], case_sensitive: false }
end
