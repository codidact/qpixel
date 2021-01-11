class Ability < ApplicationRecord
  include CommunityRelated

  validates :internal_id, uniqueness: { scope: [:community_id] }

  def manual?
    post_score_threshold.nil? && edit_score_threshold.nil? && flag_score_threshold.nil?
  end

  def self.on_user(user)
    Ability.where(id: UserAbility.where(community_user: user.community_user).select(:ability_id).distinct)
  end

  def self.trust_levels
    {
      0 => 'everyone',
      1 => 'anyone with a user account',
      2 => 'all but new users',
      3 => 'veteran users',
      4 => 'moderators only',
      5 => 'staff only'
    }
  end

  def self.[](key)
    find_by internal_id: key
  end
end
