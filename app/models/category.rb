class Category < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :post_types

  validates :name, uniqueness: { scope: [:community_id] }
end
