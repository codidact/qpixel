class CommunityUser < ApplicationRecord
  belongs_to :community
  belongs_to :user

  validates :user_id, uniqueness: { scope: [:community_id] }

  scope :for_context, -> { where(community_id: RequestContext.community_id) }

  def suspended?
    is_suspended
  end
end
