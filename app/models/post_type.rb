class PostType < ApplicationRecord
  has_many :posts
  has_and_belongs_to_many :categories

  validates :name, uniqueness: true

  def self.mapping
    Rails.cache.fetch 'post_type_ids' do
      PostType.all.map { |pt| [pt.name, pt.id] }.to_h
    end
  end

  def self.[](key)
    PostType.find_by(name: key)
  end
end
