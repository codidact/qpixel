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

  test 'adding an answer should increase answer_count' do
    question = posts(:question_one)
    pre_count = question.answer_count
    Post.create(body_markdown: 'abcde fghij klmno pqrst uvwxyz', body: '<p>abcde fghij klmno pqrst uvwxyz</p>',
                score: 0, user: users(:standard_user), parent: question, post_type_id: Answer.post_type_id)
    post_count = question.answer_count
    assert_equal pre_count + 1, post_count
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
end
