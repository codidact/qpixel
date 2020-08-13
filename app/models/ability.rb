class Ability < ApplicationRecord
  include CommunityRelated

  def manual?
    post_score_threshold.nil? && edit_score_threshold.nil? && flag_score_threshold.nil?
  end

  def self.on_user(user)
    Ability.where(id: UserAbility.where(community_user: user.community_user).select(:ability_id).distinct)
  end
end
