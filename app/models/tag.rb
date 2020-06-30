class Tag < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :posts
  has_many :children, class_name: 'Tag', foreign_key: :parent_id
  belongs_to :tag_set
  belongs_to :parent, class_name: 'Tag', optional: true

  validates :excerpt, length: { maximum: 600 }, allow_blank: true
  validates :wiki_markdown, length: { maximum: 30000 }, allow_blank: true

  def self.search(term)
    where('name LIKE ?', "%#{sanitize_sql_like(term)}%")
      .order(sanitize_sql_array(['name LIKE ? DESC, name', "#{sanitize_sql_like(term)}%"]))
  end

  def all_children
    query = File.read(Rails.root.join('db/scripts/tag_children.sql'))
    query = query.gsub('$ParentId', id.to_s)
    ActiveRecord::Base.connection.execute(query).to_a.map(&:first)
  end
end
