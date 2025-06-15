require 'test_helper'

class CommunityUserTest < ActiveSupport::TestCase
  test 'score getters should correctly calculate scores' do
    std = community_users(:sample_standard_user)

    [:edit_score, :flag_score, :post_score].each do |name|
      next unless std.respond_to?(name)

      score = std.send(name)
      assert score.positive? && score < 1
    end
  end
end
