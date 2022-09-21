class PostFlagType < ApplicationRecord
  include CommunityRelated

  belongs_to :post_type, optional: true

  validates :name, uniqueness: { scope: [:community_id], case_sensitive: false }

  scope :not_confidential, -> { where(confidential: false) }
  scope :confidential, -> { where(confidential: true) }
end
