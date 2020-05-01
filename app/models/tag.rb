class Tag < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :posts
  belongs_to :tag_set

  def self.search(term)
    where('name LIKE ?', "#{sanitize_sql_like(term)}%")
  end
end
