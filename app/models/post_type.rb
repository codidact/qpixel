class PostType < ApplicationRecord
  has_many :posts
  has_many :category_post_types
  has_many :categories, through: :category_post_types
  belongs_to :answer_type, required: false, class_name: 'PostType'

  validates :name, uniqueness: { case_sensitive: false }
  validates :answer_type_id, presence: true, if: :has_answers?

  def reactions
    Rails.cache.fetch_collection "post_type/#{name}/reactions" do
      return [] unless has_reactions

      if has_only_specific_reactions
        ReactionType.active.where(post_type: self)
      else
        ReactionType.active.where(post_type: self).or(ReactionType.active.where(post_type: nil))
      end.order(position: :asc).all
    end
  end

  # @return [Boolean] whether the post type is a system type
  def system?
    ['HelpDoc', 'PolicyDoc'].include?(name)
  end

  def self.clear_ids_cache
    Rails.cache.delete 'network/post_types/post_type_ids', include_community: false
  end

  def self.mapping
    Rails.cache.fetch 'network/post_types/post_type_ids', include_community: false do
      PostType.all.to_h { |pt| [pt.name, pt.id] }
    end
  end

  def self.[](key)
    PostType.find_by(name: key)
  end

  def self.top_level
    Rails.cache.fetch_collection 'network/post_types/top_level', include_community: false do
      where(is_top_level: true)
    end
  end

  def self.second_level
    Rails.cache.fetch_collection 'network/post_types/second_level', include_community: false do
      where(is_top_level: false)
    end
  end
end
