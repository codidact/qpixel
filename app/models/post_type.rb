class PostType < ApplicationRecord
  has_many :posts
  has_many :category_post_types
  has_many :categories, through: :category_post_types

  validates :name, uniqueness: true

  def self.mapping
    Rails.cache.fetch 'network/post_types/post_type_ids', include_community: false do
      PostType.all.map { |pt| [pt.name, pt.id] }.to_h
    end
  end

  def self.[](key)
    PostType.find_by(name: key)
  end

  def self.top_level
    Rails.cache.fetch 'network/post_types/top_level', include_community: false do
      where(is_top_level: true)
    end
  end

  def self.second_level
    Rails.cache.fetch 'network/post_types/second_level', include_community: false do
      where(is_top_level: false)
    end
  end
end
