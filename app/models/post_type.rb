class PostType < ApplicationRecord
  has_many :posts

  validates :name, uniqueness: true

  def self.mapping
    Rails.cache.fetch "#{Rails.env}__post_type_ids" do
      PostType.all.map { |pt| [pt.name, pt.id] }.to_h
    end
  end
end