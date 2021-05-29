class Tag < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :posts
  has_many :children, class_name: 'Tag', foreign_key: :parent_id
  has_many :children_with_paths, class_name: 'TagWithPath', foreign_key: :parent_id
  has_many :post_history_tags
  belongs_to :tag_set
  belongs_to :parent, class_name: 'Tag', optional: true

  validates :excerpt, length: { maximum: 600 }, allow_blank: true
  validates :wiki_markdown, length: { maximum: 30_000 }, allow_blank: true
  validates :name, presence: true, format: { with: /[^ \t]+/, message: 'Tag names may not include spaces' }
  validate :parent_not_self
  validate :parent_not_own_child
  validates :name, uniqueness: { scope: [:tag_set_id] }

  def self.search(term)
    where('name LIKE ?', "%#{sanitize_sql_like(term)}%")
      .order(Arel.sql(sanitize_sql_array(['name LIKE ? DESC, name', "#{sanitize_sql_like(term)}%"])))
  end

  def all_children
    query = File.read(Rails.root.join('db/scripts/tag_children.sql'))
    query = query.gsub('$ParentId', id.to_s)
    ActiveRecord::Base.connection.execute(query).to_a.map(&:first)
  end

  def parent_chain
    Enumerator.new do |enum|
      parent_group = group
      until parent_group.nil?
        enum.yield parent_group
        parent_group = parent_group.group
      end
    end
  end

  private

  def parent_not_self
    return if parent_id.blank?

    if parent_id == id
      errors.add(:base, 'A tag cannot be its own parent.')
    end
  end

  def parent_not_own_child
    return if parent_id.blank?

    if all_children.include? parent_id
      errors.add(:base, "The #{parent.name} tag is already a child of this tag.")
    end
  end
end
