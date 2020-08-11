class TrustLevel < ApplicationRecord
  include CommunityRelated

  def manual?
    post_score_threshold.nil? && edit_score_threshold.nil? && flag_score_threshold.nil?
  end

  def self.by_user(user)
    privileges = UserPrivilege.where(community_user: user.community_user).all

    privileges.map do |p|
      p.trust_level
    end
  end
end
