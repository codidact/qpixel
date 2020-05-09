class Tag < ApplicationRecord
  include CommunityRelated

  scope :category_order, -> (required_ids, topic_ids) do
    helpers = ActionController::Base.helpers
    order(Arel.sql("id IN #{sanitize_sql_in(required_ids)} DESC"),
          Arel.sql("id IN #{sanitize_sql_in(topic_ids)} DESC"),
          name: :asc)
  end

  has_and_belongs_to_many :posts
  belongs_to :tag_set

  def self.search(term)
    where('name LIKE ?', "#{sanitize_sql_like(term)}%")
  end
end
