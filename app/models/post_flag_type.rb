class PostFlagType < ApplicationRecord
    include CommunityRelated

    validates :name, uniqueness: { scope: [:community_id] }
end
