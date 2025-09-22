class Ability < ApplicationRecord
  include CommunityRelated
  include AbilitiesHelper

  validates :internal_id, uniqueness: { scope: [:community_id], case_sensitive: false }

  def manual?
    post_score_threshold.nil? && edit_score_threshold.nil? && flag_score_threshold.nil?
  end

  # Gets the edit score percent for a given user
  # @param user [User, nil] user to get the percent for
  # @return [Integer] edit score percent
  def edit_score_percent_for(user)
    return 0 if edit_score_threshold.nil? || user.nil?
    return 100 if edit_score_threshold.zero?

    linear_score = linearize_progress(user.community_user.edit_score)
    linear_threshold = linearize_progress(edit_score_threshold)

    (linear_score / linear_threshold * 100).to_i
  end

  # Gets the flag score percent for a given user
  # @param user [User, nil] user to get the percent for
  # @return [Integer] flag score percent
  def flag_score_percent_for(user)
    return 0 if flag_score_threshold.nil? || user.nil?
    return 100 if flag_score_threshold.zero?

    linear_score = linearize_progress(user.community_user.flag_score)
    linear_threshold = linearize_progress(flag_score_threshold)

    (linear_score / linear_threshold * 100).to_i
  end

  # Gets the post score percent for a given user
  # @param user [User, nil] user to get the percent for
  # @return [Integer] post score percent
  def post_score_percent_for(user)
    return 0 if post_score_threshold.nil? || user.nil?
    return 100 if post_score_threshold.zero?

    linear_score = linearize_progress(user.community_user.post_score)
    linear_threshold = linearize_progress(post_score_threshold)

    (linear_score / linear_threshold * 100).to_i
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
