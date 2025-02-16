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
    stripped = term.strip
    # Query to search on tags, the name is used for sorting.
    q1 = where('tags.name LIKE ?', "%#{sanitize_sql_like(stripped)}%")
         .or(where('tags.excerpt LIKE ?', "%#{sanitize_sql_like(stripped)}%"))
         .select(Arel.sql('name AS sortname, tags.*'))

    # Query to search on synonyms, the synonym name is used for sorting.
    # The order clause here actually applies to the union of q1 and q2 (so not just q2).
    q2 = joins(:tag_synonyms)
         .where('tag_synonyms.name LIKE ?', "%#{sanitize_sql_like(stripped)}%")
         .select(Arel.sql('tag_synonyms.name AS sortname, tags.*'))
         .order(Arel.sql(sanitize_sql_array(['sortname LIKE ? DESC, sortname', "#{sanitize_sql_like(stripped)}%"])))

    # Select from the union of the above queries, select only the tag columns such that we can distinct them
    from(Arel.sql("(#{q1.to_sql} UNION #{q2.to_sql}) tags"))
      .select(Tag.column_names.map { |c| "tags.#{c}" })
      .distinct
  end

  ##
  # Find or create a tag within a given tag set, considering synonyms. If a synonym is given as +name+ then the primary
  # tag for it is returned instead.
  # @param name [String] A tag name to find or create.
  # @param tag_set [TagSet] The tag set within which to search for or create the tag.
  # @return [Array(Tag, String)] The found or created tag, and the final name used. If a synonymized name was given as
  #   +name+ then this will be the primary tag name.
  #
  # @example +name+ does not yet exist: a new Tag is created
  #   Tag.find_or_create_synonymized name: 'new-tag', tag_set: ...
  #   # => [Tag, 'new-tag']
  #
  # @example +name+ already exists: the existing Tag is returned
  #   Tag.find_or_create_synonymized name: 'existing-tag', tag_set: ...
  #   # => [Tag, 'existing-tag']
  #
  # @example +name+ is a synonym of 'other-tag': the Tag for 'other-tag' is returned
  #   Tag.find_or_create_synonymized name: 'synonym', tag_set: ...
  #   # => [Tag, 'other-tag']
  def self.find_or_create_synonymized(name:, tag_set:)
    existing = Tag.find_by(name: name, tag_set: tag_set)
    if existing.nil?
      synonyms = TagSynonym.joins(:tag).where(name: name, tags: { tag_set: tag_set })
      synonymized_name = synonyms.exists? ? synonyms.first.tag.name : name
      [Tag.find_or_create_by(name: synonymized_name, tag_set: tag_set), synonymized_name]
    else
      [existing, name]
    end
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
