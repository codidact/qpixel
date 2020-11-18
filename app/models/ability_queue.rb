class AbilityQueue < ApplicationRecord
  belongs_to :community_user
  scope :pending, -> { where(completed: false) }

  def self.add(user, comment)
    unless AbilityQueue.pending.where(community_user: user.community_user).any?
      AbilityQueue.create(community_user: user.community_user, comment: comment, completed: false)
    end
  end
end
