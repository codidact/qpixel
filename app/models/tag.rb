class Tag < ApplicationRecord
  include CommunityRelated

  scope :category_order, lambda { |required_ids, topic_ids|
    order(Arel.sql("tags.id IN #{sanitize_sql_in(required_ids)} DESC"),
          Arel.sql("tags.id IN #{sanitize_sql_in(topic_ids)} DESC"),
          name: :asc)
  }

  scope :category_sort_by, lambda { |required_ids, topic_ids|
    sort_by { |t| [required_ids.include?(t.id) ? 0 : 1, topic_ids.include?(t.id) ? 0 : 1, t.id] }
  }

  has_and_belongs_to_many :posts
  belongs_to :tag_set

  def self.search(term)
    where('name LIKE ?', "#{sanitize_sql_like(term)}%")
  end
end
