class AbilityQueue < ApplicationRecord
    scope :pending, -> { where(completed: false) }

    def self.add(user, comment)
        AbilityQueue.create(community_user: user.community_user, comment: comment, completed: false)
    end
end
