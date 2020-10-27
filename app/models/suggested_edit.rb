class SuggestedEdit < ApplicationRecord
  include PostRelated

  belongs_to :user

  serialize :tags_cache, Array
  serialize :before_tags_cache, Array

  belongs_to :decided_by, class_name: 'User', optional: true
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :before_tags, class_name: 'Tag', join_table: 'suggested_edits_before_tags'

  def pending?
    active
  end

  def approved?
    !active && accepted
  end

  def rejected?
    !active && !accepted
  end

  def on_question?
    post.question?
  end

  def on_article?
    post.article?
  end

  before_validation :update_tag_associations, if: :on_question? || :on_article?

  def update_tag_associations
    return if tags_cache.nil? # Don't update if this doesn't affect tags

    tags_cache.each do |tag_name|
      tag = Tag.find_or_create_by name: tag_name, tag_set: post.category.tag_set
      unless tags.include? tag
        tags << tag
      end
    end

    tags.each do |tag|
      unless tags_cache.include? tag.name
        tags.delete tag
      end
    end
  end
end
