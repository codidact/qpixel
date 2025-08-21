require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'search should correctly narrow down users by username' do
    users = User.search('deleted')

    users.each do |u|
      assert_equal true, u.username.include?('deleted')
    end
  end

  test 'search should match any substring in usernames' do
    users = User.search('oderat')

    users.each do |u|
      assert_equal true, u.username.include?('oderat')
    end
  end

  test 'users should be destructible in a single call' do
    assert_nothing_raised do
      users(:standard_user).destroy!
    end
  end

  test 'privilege? should check against abilities for a standard user' do
    assert_equal false, users(:standard_user).privilege?('flag_close')
    assert_equal true, users(:closer).privilege?('flag_close')
  end

  test 'privilege? should grant all to admins and moderators' do
    assert_equal true, users(:global_moderator).privilege?('flag_curate')
    assert_equal true, users(:global_admin).privilege?('flag_curate')
  end

  test 'has_post_privilege should grant all to OP' do
    assert_equal true, users(:standard_user).post_privilege?('flag_curate', posts(:question_one))
  end

  test 'website_domain should strip out everything but domain' do
    assert_equal 'example.com', users(:closer).website_domain
  end

  test 'can_close? should correctly determine if the user can close a given post' do
    closer = users(:closer)

    assert closer.can_close?(posts(:question_one))
    assert_not closer.can_close?(posts(:answer_one))
    assert_not closer.can_close?(posts(:locked))

    std = users(:standard_user)

    posts.each do |post|
      if post.locked? || !post.closeable?
        assert_not std.can_close?(post)
      else
        assert_equal post.user.same_as?(std), std.can_close?(post)
      end
    end
  end

  test 'can_update? should determine if the user can update a given post' do
    basic_user = users(:basic_user)
    post_owner = users(:standard_user)
    category = categories(:main)
    license = licenses(:cc_by_sa)
    post_type = post_types(:question)
    post = Post.create(body_markdown: 'rev 1',
                       body: '<p>rev 1</p>',
                       title: 'test post',
                       tags_cache: ['test'],
                       license: license,
                       score: 0,
                       user: post_owner,
                       post_type: post_type,
                       category: category)

    assert_equal true, post_owner.can_update?(post, post_type)
    assert_equal false, basic_user.can_update?(post, post_type)
    assert_equal true, users(:moderator).can_update?(post, post_type)
    assert_equal true, users(:editor).can_update?(post, post_type)

    basic_user.community_user.grant_privilege!('unrestricted')
    assert_equal false, basic_user.can_update?(post, post_type)
    assert_equal true, basic_user.can_update?(post, post_types(:free_edit))
  end

  test 'can_push_to_network? should determine if the user can push updates to network' do
    post_type = post_types(:help_doc)
    assert_equal false, users(:standard_user).can_push_to_network?(post_type)
    assert_equal true, users(:global_moderator).can_push_to_network?(post_type)
    assert_equal true, users(:global_admin).can_push_to_network?(post_type)
  end

  test 'community_user is based on context' do
    user = users(:standard_user)
    community = Community.create(host: 'other', name: 'Other')
    copy_abilities(community.id)
    RequestContext.community = community
    cu1 = user.community_users.create(community: community)
    assert_equal user.community_user.reload, cu1
  end

  test 'at_least_moderator? for community moderator' do
    assert_equal users(:moderator).at_least_moderator?, true
  end

  test 'at_least_moderator? for community moderator in another context' do
    RequestContext.community = Community.create(host: 'other', name: 'Other')
    assert_equal users(:moderator).at_least_moderator?, false
  end

  test 'at_least_moderator? for global moderator' do
    assert_equal users(:global_moderator).at_least_moderator?, true
  end

  test 'at_least_global_moderator?' do
    admin = users(:admin)
    mod = users(:moderator)
    global_admin = users(:global_admin)
    global_mod = users(:global_moderator)

    assert_equal admin.at_least_global_moderator?, false
    assert_equal mod.at_least_global_moderator?, false
    assert_equal global_mod.at_least_global_moderator?, true
    assert_equal global_admin.at_least_global_moderator?, true
  end

  test 'admin? for community admin' do
    assert_equal users(:admin).admin?, true
  end

  test 'admin? for community admin in another context' do
    RequestContext.community = Community.create(host: 'other', name: 'Other')
    assert_equal users(:admin).admin?, false
  end

  test 'admin? for global admin' do
    assert_equal users(:global_admin).admin?, true
  end

  test 'ensure_community_user! does not alter existing community_user' do
    user = users(:standard_user)
    original_count = user.community_users.count
    original_cu = user.community_user
    user.reload
    cu = user.ensure_community_user!
    current_cu = user.community_user
    assert_equal cu, original_cu
    assert_equal cu, current_cu
    assert_equal user.community_users.count, original_count
  end

  test 'ensure_community_user! creates community_user for new communities' do
    RequestContext.community = Community.create(host: 'other', name: 'Other')

    copy_abilities(RequestContext.community_id)

    user = users(:standard_user)
    original_count = user.community_users.count
    original_cu = user.community_user
    user.reload
    cu = user.ensure_community_user!
    current_cu = user.community_user
    assert_nil original_cu
    assert_not_nil current_cu
    assert_equal cu, current_cu
    assert_equal user.community_users.count, original_count + 1
  end

  test 'moderator_on? should only be true for users that are moderators or admins on a community' do
    community = communities(:sample)
    basic = users(:basic_user)
    std = users(:standard_user)
    mod = users(:moderator)
    admin = users(:admin)

    assert_equal basic.moderator_on?(community.id), false
    assert_equal std.moderator_on?(community.id), false
    assert_equal mod.moderator_on?(community.id), true
    assert_equal admin.moderator_on?(community.id), true
  end

  test 'moderator_on? should always be true for global moderators and admins with profile on a community' do
    global_mod = users(:global_moderator)
    global_admin = users(:global_admin)

    communities.each do |c|
      assert_equal global_mod.moderator_on?(c.id), global_mod.profile_on?(c.id)
      assert_equal global_admin.moderator_on?(c.id), global_admin.profile_on?(c.id)
    end
  end

  test 'ability_on? should be false for users that do not have a profile on a community' do
    fake = communities(:fake)
    basic = users(:basic_user)
    std = users(:standard_user)
    mod = users(:moderator)
    admin = users(:admin)

    abilities.each do |ability|
      assert_equal basic.ability_on?(fake.id, ability.internal_id), false
      assert_equal std.ability_on?(fake.id, ability.internal_id), false
      assert_equal mod.ability_on?(fake.id, ability.internal_id), false
      assert_equal admin.ability_on?(fake.id, ability.internal_id), false
    end
  end

  test 'ability_on? should always be true for moderators and admins with profile on a community' do
    community = communities(:sample)
    mod = users(:moderator)
    admin = users(:admin)

    abilities.each do |ability|
      assert_equal mod.ability_on?(community.id, ability.internal_id), true
      assert_equal admin.ability_on?(community.id, ability.internal_id), true
    end
  end

  test 'ability_on? should return true for every undeleted user with profile on a community' do
    everyone = abilities(:everyone)

    communities.each do |community|
      CommunityUser.unscoped.undeleted.where(community_id: community.id).each do |cu|
        unless cu.user.deleted
          assert cu.user.ability_on?(community.id, everyone.internal_id),
                 "Expected user '#{cu.user.username}' to have the 'everyone' ability"
        end
      end
    end
  end

  test 'ability_on? should correctly check for unrestricted ability' do
    community = communities(:sample)
    basic = users(:basic_user)
    system = users(:system)

    unrestricted = abilities(:unrestricted)

    [basic, system].each do |user|
      assert_equal user.ability_on?(community.id, unrestricted.internal_id), false
    end

    CommunityUser.unscoped.undeleted.where(community_id: community.id).where.not(user_id: [basic.id, system.id]).each do |cu|
      assert_equal cu.user.ability_on?(community.id, unrestricted.internal_id), !cu.user.deleted
    end
  end

  test 'metric should correctly return user stats' do
    std = users(:editor)

    ['p', '1', '2', 's', 'v', 'V', 'E'].each do |name|
      count = std.metric(name)
      assert count.positive?, "Expected metric #{name} to be positive, actual: #{count}"
    end
  end

  test 'no_blank_unicode_in_username validation should fail if the username contains blank Unicode chars' do
    user = User.new(id: 42, username: "\u200BWhy\u200Bso\u200Bmuch\u200Bspace?")

    assert_equal false, user.valid?
    assert(user.errors[:username]&.any? { |m| m.include?('blank unicode') })
  end

  test 'no_links_in_username validation should fail if the username contains URLs' do
    user = User.new(id: 42, username: 'Visit our https://example.com site!')

    assert_equal false, user.valid?
    assert(user.errors[:username]&.any? { |m| m.include?('links') })
  end

  test 'username_not_fake_admin validation should fail if the username contains a resticted badge' do
    admin_badge = SiteSetting['AdminBadgeCharacter']
    mod_badge = SiteSetting['ModBadgeCharacter']

    [admin_badge, mod_badge].each do |badge|
      user = User.new(id: 42, username: "I am totally a #{badge}")

      assert_equal false, user.valid?
      assert(user.errors[:username]&.any? { |m| m.include?(badge) })
    end
  end

  test 'inspect should work with the model' do
    std = users(:standard_user)

    assert_nothing_raised do
      std.inspect
    end
  end

  test 'moderator_communities should correctly list mod communities' do
    Community.create(name: 'Test', host: 'test.host')

    global_result = users(:global_moderator).moderator_communities
    assert_equal Community.all.size, global_result.size

    local_result = users(:moderator).moderator_communities
    assert_equal 1, local_result.size
  end

  test 'admin_communities should correctly list admin communities' do
    Community.create(name: 'Test', host: 'test.host')

    global_result = users(:global_admin).admin_communities
    assert_equal Community.all.size, global_result.size

    local_result = users(:admin).admin_communities
    assert_equal 1, local_result.size
  end
end
