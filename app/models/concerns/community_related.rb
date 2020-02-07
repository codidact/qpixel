module CommunityRelated
  extend ActiveSupport::Concern

  included do
    belongs_to :community
    default_scope { where(community_id: RequestContext.community_id) }
  end
end
