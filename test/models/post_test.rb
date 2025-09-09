require 'test_helper'

class PostTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is community related' do
    assert_community_related(Post)
  end

  test 'deleting a post should remove reputation change' do
    post = posts(:answer_one)
    previous_rep = post.user.reputation
    expected_change = Vote.total_rep_change(post.votes)
    post.update(deleted: true)
    assert_equal previous_rep - expected_change, post.user.reputation
  end

  test 'undeleting a post should restore reputation change' do
    post = posts(:answer_one)
    post.update(deleted: true)

    previous_rep = post.user.reputation
    expected_change = Vote.total_rep_change(post.votes)
    post.update(deleted: false)
    assert_equal previous_rep + expected_change, post.user.reputation
  end

  test 'deleting an old post should not remove reputation change' do
    post = posts(:really_old_answer)
    previous_rep = post.user.reputation
    post.update(deleted: true)
    assert_equal previous_rep, post.user.reputation
  end

  test 'reassigning post should move post votes and rep change' do
    post = posts(:question_one)
    rep_change = Vote.total_rep_change(post.votes)
    original_author_rep = post.user.reputation
    original_transferee_rep = users(:editor).reputation
    post.reassign_user(users(:editor))
    assert_equal false, post.deleted
    assert_equal original_author_rep - rep_change, users(:standard_user).reputation
    assert_equal original_transferee_rep + rep_change, users(:editor).reputation
    assert_equal post.user_id, users(:editor).id
    post.votes.each do |vote|
      assert_equal users(:editor).id, vote.recv_user_id
    end
  end

  test 'accessible_to should correctly check user access' do
    adm_user = users(:admin)
    mod_user = users(:moderator)
    std_user = users(:standard_user)

    adm_posts = Post.accessible_to(adm_user)
    mod_posts = Post.accessible_to(mod_user)
    std_posts = Post.accessible_to(std_user)

    can_admin_get_deleted_posts = adm_posts.any?(&:deleted)
    can_mod_get_deleted_posts = mod_posts.any?(&:deleted)
    can_user_get_deleted_posts = std_posts.any?(&:deleted)

    assert can_admin_get_deleted_posts
    assert can_mod_get_deleted_posts
    assert_not can_user_get_deleted_posts
  end

  test 'should allow specified post types in a category' do
    category = categories(:main)
    post_type = post_types(:question)
    post = Post.create(body_markdown: 'abcde fghij klmno pqrst uvwxyz', body: '<p>abcde fghij klmno pqrst uvwxyz</p>',
                       title: 'abcd efgh ijkl mnop', tags_cache: ['discussion'], license: licenses(:cc_by_sa),
                       score: 0, user: users(:standard_user), post_type: post_type, category: category)
    assert_equal false, post.errors.any?, 'Category-allowed post type had errors on save'
    assert_not_nil post.id
    assert_equal category.id, post.category_id
    assert_equal post_type.id, post.post_type_id
  end

  test 'should not allow unspecified post types in a category' do
    category = categories(:main)
    post_type = post_types(:help_doc)
    post = Post.create(body_markdown: 'abcde fghij klmno pqrst uvwxyz', body: '<p>abcde fghij klmno pqrst uvwxyz</p>',
                       title: 'abcd efgh ijkl mnop', tags_cache: ['discussion'],
                       score: 0, user: users(:standard_user), post_type: post_type, category: category)
    assert_equal true, post.errors.any?, 'Category-disallowed post type had no errors on save'
    assert_equal "The #{post_type.name} post type is not allowed in the #{category.name} category.",
                 post.errors.full_messages[0]
    assert_nil post.id
  end

  test 'reaction list should be empty if none has been added' do
    post_without_reactions = posts(:answer_two)
    reaction_list = post_without_reactions.reaction_list
    assert reaction_list.empty?
  end

  test 'reaction list should be not empty if one has been added' do
    post_with_reactions = posts(:answer_one)
    reaction_list = post_with_reactions.reaction_list
    refute reaction_list.empty?
    assert reaction_list.key?(reaction_types(:wfm))
    assert_equal 1, reaction_list[reaction_types(:wfm)].count
  end

  test 'moderator_tags should correctly validate if the user can use moderator tags on posts' do
    category = categories(:moderator_tags)
    post_type = post_types(:question)

    users.each do |user|
      # moderator_tags validation requires request context user to be set
      RequestContext.user = user

      post = Post.new(body_markdown: 'm' * category.min_body_length, body: "<p>#{'b' * category.min_body_length}</p>",
                      title: 't' * category.min_title_length, tags_cache: ['feature-request'], license: licenses(:cc_by_sa),
                      score: 0, user: user, post_type: post_type, category: category)

      if post.valid?
        assert_equal user.at_least_moderator?, true
      else
        assert_not_empty post.errors[:mod_tags]
      end
    end
  end

  test 'closeable? should correctly determine if the post can be closed' do
    post_types.each do |post_type|
      Post.where(post_type: post_type).each do |post|
        assert_equal post.closeable?, post_type.is_closeable
      end
    end
  end

  test 'deleted_by_owner? should correctly determine if the post is deleted by its owner' do
    posts.reject(&:deleted).each do |post|
      assert_not post.deleted_by_owner?
    end
  end
end
