require 'test_helper'

class VoteTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is post related' do
    assert_post_related(Vote)
  end

  test 'creating a vote should correctly change user reputation' do
    [1, -1].each do |vote_type|
      previous_rep = posts(:question_two).user.reputation
      expected_change = CategoryPostType.rep_changes[[posts(:question_two).category_id, post_types(:question).id]][vote_type]
      posts(:question_two).votes.create(user: users(:deleter), recv_user: posts(:question_two).user, vote_type: vote_type)
      assert_equal posts(:question_two).user.reputation, previous_rep + expected_change
    end
  end

  test 'multiple votes should result in correct post score and user reputation' do
    post = posts(:question_two)
    author = post.user
    previous_rep = author.reputation

    rep_change_up = post_types(:question).upvote_rep
    rep_change_down = post_types(:question).downvote_rep
    expected_rep_change = 3 * rep_change_up + 2 * rep_change_down

    post.votes.create([
                        { user: users(:standard_user), recv_user: author, vote_type: 1 },
                        { user: users(:closer), recv_user: author, vote_type: 1 },
                        { user: users(:deleter), recv_user: author, vote_type: 1 },
                        { user: users(:moderator), recv_user: author, vote_type: -1 },
                        { user: users(:admin), recv_user: author, vote_type: -1 }
                      ])

    assert_equal post.votes.count, 5
    assert_equal post.upvote_count, 3
    assert_equal post.downvote_count, 2
    assert_equal author.reputation, previous_rep + expected_rep_change
  end

  test 'Vote.total_rep_change should result in correct rep change for given votes' do
    post = posts(:answer_one)
    rep_change_up = post_types(:answer).upvote_rep
    rep_change_down = post_types(:answer).downvote_rep
    expected = 4 * rep_change_up + 1 * rep_change_down
    assert_equal expected, Vote.total_rep_change(post.votes)
  end
end
