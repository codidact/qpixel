module MaybeCommunityRelated
  extend ActiveSupport::Concern

  included do
    belongs_to :community, required: false
    default_scope { where(community_id: RequestContext.community_id).or(where(community_id: nil)) }
  end
end
