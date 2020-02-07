class CommunityUser < ApplicationRecord
  belongs_to :community
  belongs_to :user

  scope :for_context, ->{ where(community_id: RequestContext.community_id) }
end
