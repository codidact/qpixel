module TagsHelper
  def category_sort_tags(tags, required_ids, topic_ids)
    tags
      .to_a
      .sort_by { |t| [required_ids.include?(t.id) ? 0 : 1, topic_ids.include?(t.id) ? 0 : 1, t.id] }
  end
end