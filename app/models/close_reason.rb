class CloseReason < ApplicationRecord
  include MaybeCommunityRelated

  scope :active, -> { where(active: true) }

  validates :name, length: { maximum: 255 },
                   presence: true,
                   uniqueness: { scope: [:community_id], case_sensitive: false }

  # Gets close reasons appropriately scoped for a given user
  # @param user [User, nil] user to check
  # @return [ActiveRecord::Relation<CloseReason>]
  def self.accessible_to(user)
    if user&.global_admin?
      CloseReason.unscoped
    elsif RequestContext.community_id.present?
      CloseReason.where(community_id: RequestContext.community_id)
    else
      CloseReason.none
    end
  end

  # Is the close reason network-wide (global)?
  # @return [Boolean] check result
  def global?
    community.nil?
  end
end
