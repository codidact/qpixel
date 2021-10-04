class ReactionType < ApplicationRecord
  include CommunityRelated
  belongs_to :post_type, class_name: 'PostType', optional: true
  scope :active, -> { where(active: true) }
end
