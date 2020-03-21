class TagSet < ApplicationRecord
  include CommunityRelated
  has_many :tags

  validates :name, uniqueness: { scope: [:community_id] }
end
