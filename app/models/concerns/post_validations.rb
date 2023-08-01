# Validations for posts which are shared between posts and suggested edits.
module PostValidations
  extend ActiveSupport::Concern

  included do
    validate :tags_in_tag_set, if: -> { post_type.has_tags }
    validate :maximum_tags, if: -> { post_type.has_tags }
    validate :maximum_tag_length, if: -> { post_type.has_tags }
    validate :no_spaces_in_tags, if: -> { post_type.has_tags }
    validate :stripped_minimum_body, if: -> { !body_markdown.nil? }
    validate :stripped_minimum_title, if: -> { !title.nil? }
    validate :maximum_title_length, if: -> { !title.nil? }
    validate :required_tags?, if: -> { post_type.has_tags && post_type.has_category }
  end

  def maximum_tags
    if tags_cache.length > 5
      errors.add(:base, "Post can't have more than 5 tags.")
    elsif tags_cache.empty?
      errors.add(:base, 'Post must have at least one tag.')
    end
  end

  def maximum_tag_length
    tags_cache.each do |tag|
      max_len = SiteSetting['MaxTagLength']
      if tag.length > max_len
        errors.add(:tags, "can't be more than #{max_len} characters long each")
      end
    end
  end

  def no_spaces_in_tags
    tags_cache.each do |tag|
      if tag.include?(' ') || tag.include?('_')
        errors.add(:tags, 'may not include spaces or underscores - use hyphens for multiple-word tags')
      end
    end
  end

  def stripped_minimum_body
    min_body = category.nil? ? 30 : category.min_body_length
    if (body_markdown&.gsub(/(?:^[\s\t\u2000-\u200F]+|[\s\t\u2000-\u200F]+$)/, '')&.length || 0) < min_body
      errors.add(:body, 'must be more than 30 non-whitespace characters long')
    end
  end

  def stripped_minimum_title
    min_title = category.nil? ? 15 : category.min_title_length
    if (title&.gsub(/(?:^[\s\t\u2000-\u200F]+|[\s\t\u2000-\u200F]+$)/, '')&.length || 0) < min_title
      errors.add(:title, 'must be more than 15 non-whitespace characters long')
    end
  end

  def maximum_title_length
    max_title_len = SiteSetting['MaxTitleLength']
    if title.length > [(max_title_len || 255), 255].min
      errors.add(:title, "can't be more than #{max_title_len} characters")
    end
  end

  def tags_in_tag_set
    tag_set = category.tag_set
    unless tags.all? { |t| t.tag_set_id == tag_set.id }
      errors.add(:base, "Not all of this question's tags are in the correct tag set.")
    end
  end

  def required_tags?
    required = category&.required_tag_ids
    return unless required.present? && !required.empty?

    unless tag_ids.any? { |t| required.include? t }
      errors.add(:tags, "must contain at least one required tag (#{category.required_tags.pluck(:name).join(', ')})")
    end
  end
end
