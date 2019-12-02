class PostType < ApplicationRecord
  has_many :posts

  validates :name, uniqueness: true

  def self.mapping
    Rails.cache.read 'post_type_ids'
  end
end