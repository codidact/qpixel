class ReactionType < ApplicationRecord
  include CommunityRelated
  scope :active, -> { where(active: true).order(position: :asc) }
end
