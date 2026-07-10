class AbilityQueue < ApplicationRecord
  belongs_to :community_user
  scope :pending, -> { where(completed: false) }

  ##
  # Are there pending ability queue entries for a given user?
  # @param user [User] user to check the queue for
  # @return [Boolean] check result
  def self.pending_for?(user)
    AbilityQueue.pending.where(community_user: user.community_user).any?
  end

  ##
  # Adds a new ability queue entry for a user if one does not already exist.
  # @param user [User] user to add queue entry for
  # @param comment [String] comment to add to queue entry
  def self.add(user, comment)
    return if AbilityQueue.pending_for?(user)
    AbilityQueue.create(community_user: user.community_user, comment: comment, completed: false)
  end

  ##
  # Adds a new ability queue entry for a user if one does not already exist.
  # Executes create as an ActiveRecord bang method.
  # @param user [User] user to add queue entry for
  # @param comment [String] comment to add to queue entry
  def self.add!(user, comment)
    return if AbilityQueue.pending_for?(user)
    AbilityQueue.create!(community_user: user.community_user, comment: comment, completed: false)
  end
end
