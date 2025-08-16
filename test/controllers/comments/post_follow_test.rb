require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'post follower can unfollow post' do
    user = users(:standard_user)
    sign_in user
    question = posts(:question_one)

    # Assert user follows post
    assert_equal 1, ThreadFollower.where(['post_id = ? AND user_id = ?', question, user]).count

    try_post_unfollow(question)
    assert_response(:found)

    # Assert user does not follow post
    assert_equal 0, ThreadFollower.where(['post_id = ? AND user_id = ?', question, user]).count
  end

  test 'non-follower can follow post' do
    user = users(:basic_user)
    sign_in user
    question = posts(:question_one)

    # Assert user does not follow post
    assert_equal 0, ThreadFollower.where(['post_id = ? AND user_id = ?', question, user]).count

    try_post_follow(question)
    assert_response(:found)

    # Assert user follows post
    assert_equal 1, ThreadFollower.where(['post_id = ? AND user_id = ?', question, user]).count
  end

  test 'follower cannot duplicate the following of a post' do
    user = users(:standard_user)
    sign_in user
    question = posts(:question_one)

    # Assert user follows post
    assert_equal 1, ThreadFollower.where(['post_id = ? AND user_id = ?', question, user]).count

    try_post_follow(question)
    assert_response(:found)

    # Assert user still only follows post once
    assert_equal 1, ThreadFollower.where(['post_id = ? AND user_id = ?', question, user]).count
  end
end
