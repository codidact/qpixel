require 'test_helper'

class UserTest < ActiveSupport::TestCase
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
    assert_equal true, users(:standard_user).has_post_privilege?('flag_curate', posts(:question_one))
  end

  test 'website_domain should strip out everything but domain' do
    assert_equal 'example.com', users(:closer).website_domain
  end

  test 'can_update should determine if the user can update a given post' do
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

    assert_equal true, post_owner.can_update(post, post_type)
    assert_equal false, basic_user.can_update(post, post_type)
    assert_equal true, users(:moderator).can_update(post, post_type)
    assert_equal true, users(:editor).can_update(post, post_type)

    basic_user.community_user.grant_privilege!('unrestricted')
    assert_equal false, basic_user.can_update(post, post_type)
    assert_equal true, basic_user.can_update(post, post_types(:free_edit))
  end

  test 'can_push_to_network should determine if the user can push updates to network' do
    post_type = post_types(:help_doc)
    assert_equal false, users(:standard_user).can_push_to_network(post_type)
    assert_equal true, users(:global_moderator).can_push_to_network(post_type)
    assert_equal true, users(:global_admin).can_push_to_network(post_type)
  end

  test 'community_user is based on context' do
    user = users(:standard_user)
    community = Community.create(host: 'other', name: 'Other')
    copy_abilities(community.id)
    RequestContext.community = community
    cu1 = user.community_users.create(community: community)
    assert_equal user.community_user.reload, cu1
  end

  test 'is_moderator for community moderator' do
    assert_equal users(:moderator).is_moderator, true
  end

  test 'is_moderator for community moderator in another context' do
    RequestContext.community = Community.create(host: 'other', name: 'Other')
    assert_equal users(:moderator).is_moderator, false
  end

  test 'is_moderator for global moderator' do
    assert_equal users(:global_moderator).is_moderator, true
  end

  test 'is_admin for community admin' do
    assert_equal users(:admin).is_admin, true
  end

  test 'is_admin for community admin in another context' do
    RequestContext.community = Community.create(host: 'other', name: 'Other')
    assert_equal users(:admin).is_admin, false
  end

  test 'is_admin for global admin' do
    assert_equal users(:global_admin).is_admin, true
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
end
