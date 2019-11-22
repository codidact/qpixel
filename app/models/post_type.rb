class PostType < ApplicationRecord
  has_many :posts

  validates :name, uniqueness: true

  def self.mapping
    PostType.all.map { |pt| [pt.name, pt.id] }.to_h
  end
end