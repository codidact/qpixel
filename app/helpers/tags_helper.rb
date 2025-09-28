module TagsHelper
  ##
  # Sort a list of tags by importance within the context of a category's set of required, moderator, and topic tags.
  # @param tags [ActiveRecord::Relation<Tag>] A list of tags.
  # @param required_ids [Array<Integer>] A list of required tag IDs.
  # @param topic_ids [Array<Integer>] A list of topic tag IDs.
  # @param moderator_ids [Array<Integer>] A list of moderator-only tag IDs.
  # @return [Array<Tag>]
  def category_sort_tags(tags, required_ids, topic_ids, moderator_ids)
    tags
      .to_a
      .sort_by do |t|
        [required_ids.include?(t.id) ? 0 : 1, moderator_ids.include?(t.id) ? 0 : 1,
         topic_ids.include?(t.id) ? 0 : 1, t.id]
      end
  end

  ##
  # Generate a list of classes to be applied to a tag.
  # @param tag [Tag]
  # @param category [Category] The category within the context of which the tag is being displayed.
  # @return [String]
  def tag_classes(tag, category)
    required_ids = category&.required_tag_ids
    moderator_ids = category&.moderator_tag_ids
    topic_ids = category&.topic_tag_ids
    required = required_ids&.include?(tag.id) ? 'is-filled' : ''
    topic = topic_ids&.include?(tag.id) ? 'is-outlined' : ''
    moderator = moderator_ids&.include?(tag.id) ? 'is-red is-outlined' : ''
    "badge is-tag #{required} #{topic} #{moderator}"
  end

  ##
  # Get a list of post IDs that belong to any of the specified tag IDs.
  # @param tag_ids [Array<Integer>] A list of tag IDs.
  # @return [Array<Integer>] A list of post IDs.
  def post_ids_for_tags(tag_ids)
    sql = "SELECT post_id FROM posts_tags WHERE tag_id IN #{ApplicationRecord.sanitize_sql_in(tag_ids)}"
    ActiveRecord::Base.connection.execute(sql).to_a.flatten
  end

  # Gets a standard tag rename error message for a tag
  # @param post [Tag] target tag
  # @return [String] error message
  def tag_rename_error_msg(tag)
    if tag.errors.where(:name, :taken)
      I18n.t('tags.errors.rename_taken')
    else
      I18n.t('tags.errors.rename_generic')
    end
  end
end
