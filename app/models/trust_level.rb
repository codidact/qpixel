class TrustLevel < ApplicationRecord
  include CommunityRelated

  def manual?
    post_score_threshold.nil? && edit_score_threshold.nil? && flag_score_threshold.nil?
  end
end
