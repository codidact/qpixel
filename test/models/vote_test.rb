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

    cpt = CategoryPostType.find_by(category: posts(:question_two).category, post_type: posts(:question_two).post_type)
    rep_change_up = cpt.upvote_rep
    rep_change_down = cpt.downvote_rep
    expected_rep_change = (3 * rep_change_up) + (2 * rep_change_down)

    new_votes = [
      { user: users(:standard_user), recv_user: author, vote_type: 1 },
      { user: users(:closer), recv_user: author, vote_type: 1 },
      { user: users(:deleter), recv_user: author, vote_type: 1 },
      { user: users(:moderator), recv_user: author, vote_type: -1 },
      { user: users(:admin), recv_user: author, vote_type: -1 }
    ]

    post.votes.create(new_votes)

    num_votes = new_votes.length
    num_upvotes = new_votes.inject(0) { |a, c| a + (c[:vote_type] == 1 ? 1 : 0) }
    num_downvotes = new_votes.inject(0) { |a, c| a + (c[:vote_type] == -1 ? 1 : 0) }

    # NB: fixtures can & should be able to add more votes than created here
    assert post.votes.count >= num_votes, "Expected more than #{num_votes} votes, actual: #{post.votes.count}"
    assert post.upvote_count >= num_upvotes, "Expected more than #{num_upvotes} upvotes, actual: #{post.upvote_count}"
    assert post.downvote_count >= num_downvotes, "Expected more than #{num_downvotes} downvotes, actual: #{post.downvote_count}"
    assert_equal author.reputation, previous_rep + expected_rep_change
  end

  test 'total_rep_change should result in correct rep change for given votes' do
    post = posts(:answer_one)
    cpt = CategoryPostType.find_by(category: posts(:answer_one).category, post_type: posts(:answer_one).post_type)
    rep_change_up = cpt.upvote_rep
    rep_change_down = cpt.downvote_rep
    expected = (4 * rep_change_up) + (1 * rep_change_down)
    assert_equal expected, Vote.total_rep_change(post.votes)
  end
end
