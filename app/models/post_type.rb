class PostType < ApplicationRecord
  has_many :posts
  has_and_belongs_to_many :categories

  validates :name, uniqueness: true

  def self.mapping
    Rails.cache.fetch 'network/post_types/post_type_ids' do
      PostType.all.map { |pt| [pt.name, pt.id] }.to_h
    end
  end

  def self.[](key)
    PostType.find_by(name: key)
  end

  def self.rep_changes
    Rails.cache.fetch 'network/post_types/rep_changes' do
      all.map { |pt| [pt.id, { 1 => pt.upvote_rep, -1 => pt.downvote_rep }] }.to_h
    end
  end
end
