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

  test 'should correctly maintain trust_level' do
    base_trust_level = SiteSetting['NewSiteMode'] ? 2 : 1
    community = communities(:sample)
    std_usr = users(:no_community_user)

    cu = CommunityUser.create({ community_id: community.id,
                                user_id: std_usr.id })

    assert_equal base_trust_level, cu.trust_level

    cu.update({ is_moderator: true })
    cu.reload
    assert_equal 4, cu.trust_level

    std_usr.update({ staff: true })
    cu.reload
    assert_equal 5, cu.trust_level

    std_usr.update({ staff: false })
    cu.reload
    assert_equal 4, cu.trust_level

    cu.update({ is_moderator: false })
    cu.reload
    assert_equal base_trust_level, cu.trust_level
  end
end
