class Reaction < ApplicationRecord
  belongs_to :reaction_type
  belongs_to :user
  belongs_to :post
  belongs_to :comment

  default_scope { joins(:reaction_type).where(reaction_types: { community_id: RequestContext.community_id }) }
end
