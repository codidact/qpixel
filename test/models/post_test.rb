require 'test_helper'

class PostTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is commmunity related' do
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
end
