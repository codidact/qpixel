class PostFlagType < ApplicationRecord
  include CommunityRelated

  validates :name, uniqueness: { scope: [:community_id] }

  scope :not_confidential, -> { where(confidential: false) }
  scope :confidential, -> { where(confidential: true) }
end
