class ReactionType < ApplicationRecord
  include CommunityRelated
  belongs_to :post_type, class_name: 'PostType', optional: true

  validates :name, uniqueness: { scope: [:community_id], case_sensitive: false }

  scope :active, -> { where(active: true) }
end
