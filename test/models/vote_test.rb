require 'test_helper'

class VoteTest < ActiveSupport::TestCase
  include CommunityRelatedHelper

  test 'is post related' do
    assert_post_related(Vote)
  end

  test 'creating a vote should correctly change post score' do
    [1, -1].each do |vote_type|
      previous_score = posts(:question_two).score
      posts(:question_two).votes.create(user: users(:deleter), recv_user: posts(:question_two).user, vote_type: vote_type)
      assert_equal posts(:question_two).score, previous_score + vote_type
    end
  end

  test 'creating a vote should correctly change user reputation' do
    [1, -1].each do |vote_type|
      previous_rep = posts(:question_two).user.reputation
      setting_name = vote_type == 1 ? 'QuestionUpVoteRep' : 'QuestionDownVoteRep'
      expected_change = SiteSetting[setting_name]
      posts(:question_two).votes.create(user: users(:deleter), recv_user: posts(:question_two).user, vote_type: vote_type)
      assert_equal posts(:question_two).user.reputation, previous_rep + expected_change
    end
  end

  test 'multiple votes should result in correct post score and user reputation' do
    post = posts(:question_two)
    author = post.user
    previous_score = post.score
    previous_rep = author.reputation
    expected_score_change = +3 + -2

    rep_change_up = SiteSetting['QuestionUpVoteRep']
    rep_change_down = SiteSetting['QuestionDownVoteRep']
    expected_rep_change = 3 * rep_change_up + 2 * rep_change_down

    post.votes.create([
                        { user: users(:standard_user), recv_user: author, vote_type: 1 },
                        { user: users(:closer), recv_user: author, vote_type: 1 },
                        { user: users(:deleter), recv_user: author, vote_type: 1 },
                        { user: users(:moderator), recv_user: author, vote_type: -1 },
                        { user: users(:admin), recv_user: author, vote_type: -1 }
                      ])

    assert_equal post.votes.count, 5
    assert_equal post.score, previous_score + expected_score_change
    assert_equal author.reputation, previous_rep + expected_rep_change
  end

  test 'Vote.total_rep_change should result in correct rep change for given votes' do
    post = posts(:answer_one)
    rep_change_up = SiteSetting['AnswerUpVoteRep']
    rep_change_down = SiteSetting['AnswerDownVoteRep']
    expected = 4 * rep_change_up + 1 * rep_change_down
    assert_equal expected, Vote.total_rep_change(post.votes)
  end
end
