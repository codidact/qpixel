class PostType < ApplicationRecord
  has_many :posts

  validates :name, uniqueness: true

  def self.mapping
    Rails.cache.persistent 'post_type_ids'
  end
end