class Ability < ApplicationRecord
  include CommunityRelated

  def manual?
    post_score_threshold.nil? && edit_score_threshold.nil? && flag_score_threshold.nil?
  end

  def self.by_user(user)
    privileges = UserAbility.where(community_user: user.community_user).all

    privileges.map do |p|
      p.ability
    end
  end
end
