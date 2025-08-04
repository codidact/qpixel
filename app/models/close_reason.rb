class CloseReason < ApplicationRecord
  include MaybeCommunityRelated

  scope :active, -> { where(active: true) }

  validates :name, length: { maximum: 255 },
                   presence: true,
                   uniqueness: { scope: [:community_id], case_sensitive: false }

  def global?
    community.nil?
  end
end
