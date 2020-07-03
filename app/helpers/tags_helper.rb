module TagsHelper
  def category_sort_tags(tags, required_ids, topic_ids, moderator_ids)
    tags
      .to_a
      .sort_by do |t|
        [required_ids.include?(t.id) ? 0 : 1, moderator_ids.include?(t.id) ? 0 : 1,
         topic_ids.include?(t.id) ? 0 : 1, t.id]
      end
  end

  def tag_classes(tag, category)
    required_ids = category&.required_tag_ids
    moderator_ids = category&.moderator_tag_ids
    topic_ids = category&.topic_tag_ids
    required = required_ids&.include?(tag.id) ? 'is-filled' : ''
    topic = topic_ids&.include?(tag.id) ? 'is-outlined' : ''
    moderator = moderator_ids&.include?(tag.id) ? 'is-red is-outlined' : ''
    "badge is-tag #{required} #{topic} #{moderator}"
  end

  def post_ids_for_tags(tag_ids)
    sql = "SELECT post_id FROM posts_tags WHERE tag_id IN #{ApplicationRecord.sanitize_sql_in(tag_ids)}"
    ActiveRecord::Base.connection.execute(sql).to_a.flatten
  end
end
