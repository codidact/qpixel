class TagSet < ApplicationRecord
  include CommunityRelated
  has_many :tags
  has_many :tags_with_paths, class_name: 'TagWithPath'
  has_many :categories

  validates :name, uniqueness: { scope: [:community_id] }, presence: true

  def self.meta
    where(name: 'Meta').first
  end

  def self.main
    where(name: 'Main').first
  end
end
