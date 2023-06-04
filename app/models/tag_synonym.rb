class TagSynonym < ApplicationRecord
  belongs_to :tag
  has_one :community, through: :tag

  validates :name, presence: true, format: { with: /[^ \t]+/, message: 'Tag names may not include spaces' }
  validate :name_unique

  private

  # Checks whether the name of this synonym is not already taken by a tag or synonym in the same community.
  def name_unique
    if TagSynonym.joins(:tag).where(tags: { community_id: tag.community_id }).exists?(name: name)
      errors.add(:base, "A tag synonym with the name #{name} already exists.")
    elsif Tag.unscoped.where(community_id: tag.community_id).exists?(name: name)
      errors.add(:base, "A tag with the name #{name} already exists.")
    end
  end
end
