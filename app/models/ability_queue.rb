class AbilityQueue < ApplicationRecord
  belongs_to :community_user
  scope :pending, -> { where(completed: false) }

  ##
  # Adds a new ability queue entry for a user if one does not already exist.
  # @param user [User] user to add queue entry for
  # @param comment [String] comment to add to queue entry
  # @param bang [Boolean] whether to execute the create as an ActiveRecord bang method or not (default: false)
  def self.add(user, comment, bang: false)
    unless AbilityQueue.pending.where(community_user: user.community_user).any?
      if bang
        AbilityQueue.create!(community_user: user.community_user, comment: comment, completed: false)
      else
        AbilityQueue.create(community_user: user.community_user, comment: comment, completed: false)
      end
    end
  end

  ##
  # Adds a new ability queue entry for a user if one does not already exist. Executes create as an ActiveRecord bang
  # method.
  # @param user [User] user to add queue entry for
  # @param comment [String] comment to add to queue entry
  def self.add!(user, comment)
    AbilityQueue.add(user, comment, bang: true)
  end
end
