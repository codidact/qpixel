class CommunityUser < ApplicationRecord
  belongs_to :community
  belongs_to :user

  has_many :mod_warnings, dependent: :destroy

  validates :user_id, uniqueness: { scope: [:community_id] }

  scope :for_context, -> { where(community_id: RequestContext.community_id) }

  def suspended?
    return true if is_suspended && !suspension_end.past?

    if is_suspended
      update(is_suspended: false, suspension_public_comment: nil, suspension_end: nil)
    end

    false
  end
end
