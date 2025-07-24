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

  test 'latest_warning should return the timestamp of the latest warning, if any' do
    std = community_users(:sample_standard_user)

    latest = mod_warnings.select { |mw| mw.community_user == std }
                         .min { |a, b| a.created_at > b.created_at ? 1 : -1 }

    assert_equal std.latest_warning, latest&.created_at
  end
end
