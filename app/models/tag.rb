class Tag < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :posts
  has_many :children, class_name: 'Tag', foreign_key: :parent_id
  has_many :children_with_paths, class_name: 'TagWithPath', foreign_key: :parent_id
  has_many :post_history_tags
  has_many :tag_synonyms, dependent: :destroy
  accepts_nested_attributes_for :tag_synonyms, allow_destroy: true
  belongs_to :tag_set
  belongs_to :parent, class_name: 'Tag', optional: true

  validates :excerpt, length: { maximum: 600 }, allow_blank: true
  validates :wiki_markdown, length: { maximum: 30_000 }, allow_blank: true
  validates :name, presence: true, format: { with: /[^ \t]+/, message: 'Tag names may not include spaces' }
  validate :parent_not_self
  validate :parent_not_own_child
  validate :synonym_unique
  validates :name, uniqueness: { scope: [:tag_set_id], case_sensitive: false }

  def self.search(term)
    # Query to search on tags, the name is used for sorting.
    q1 = where('tags.name LIKE ?', "%#{sanitize_sql_like(term)}%")
           .or(where('tags.excerpt LIKE ?', "%#{sanitize_sql_like(term)}%"))
           .select(Arel.sql('name AS sortname, tags.*'))

    # Query to search on synonyms, the synonym name is used for sorting.
    # The order clause here actually applies to the union of q1 and q2 (so not just q2).
    q2 = joins(:tag_synonyms)
           .where('tag_synonyms.name LIKE ?', "%#{sanitize_sql_like(term)}%")
           .select(Arel.sql('tag_synonyms.name AS sortname, tags.*'))
           .order(Arel.sql(sanitize_sql_array(['sortname LIKE ? DESC, sortname', "#{sanitize_sql_like(term)}%"])))

    # Select from the union of the above queries, select only the tag columns such that we can distinct them
    from(Arel.sql("(#{q1.to_sql} UNION #{q2.to_sql}) tags"))
      .select(Tag.column_names.map { |c| "tags.#{c}" })
      .distinct
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

  def synonym_unique
    if TagSynonym.joins(:tag).where(tags: { community_id: community_id }).exists?(name: name)
      errors.add(:base, "A tag synonym with the name #{name} already exists.")
    end
  end
end
