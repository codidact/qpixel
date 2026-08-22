class CloseReason < ApplicationRecord
  include MaybeCommunityRelated

  scope :active, -> { where(active: true) }

  validates :name, length: { maximum: 255 },
                   presence: true,
                   uniqueness: { scope: [:community_id], case_sensitive: false }

  # Is the close reason network-wide (global)?
  # @return [Boolean] check result
  def global?
    community.nil?
  end
end
