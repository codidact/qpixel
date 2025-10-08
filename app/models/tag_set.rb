class TagSet < ApplicationRecord
  include CommunityRelated

  has_many :tags
  has_many :tags_with_paths, class_name: 'TagWithPath'
  has_many :categories

  validates :name, uniqueness: { scope: [:community_id], case_sensitive: false }, presence: true

  def self.meta
    where(name: 'Meta').first
  end

  def self.main
    where(name: 'Main').first
  end

  def with_paths(no_excerpt = false)
    if no_excerpt
      tags_with_paths.where(excerpt: ['', nil])
    else
      tags_with_paths
    end
  end
end
