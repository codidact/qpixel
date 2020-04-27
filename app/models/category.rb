class Category < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :post_types
  has_many :posts
  belongs_to :tag_set

  serialize :display_post_types, Array

  validates :name, uniqueness: { scope: [:community_id] }
end
