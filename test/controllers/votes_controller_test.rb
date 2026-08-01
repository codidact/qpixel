require 'test_helper'

class VotesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should cast upvote' do
    sign_in users(:standard_user)

    try_create_vote posts(:question_without_votes), 1

    assert_json_success
  end

  test 'should cast downvote' do
    sign_in users(:standard_user)

    try_create_vote posts(:question_without_votes), -1

    assert_json_success
  end

  test 'should return correct modified status' do
    post = posts(:question_without_votes)

    sign_in users(:standard_user)

    try_create_vote post, 1
    try_create_vote post, 1

    assert_json_success(status: 'modified')
  end

  test 'should silently accept duplicate votes' do
    post = posts(:question_without_votes)

    sign_in users(:standard_user)

    try_create_vote post, 1
    try_create_vote post, 1

    assert_json_success(status: 'modified')
  end

  test 'should prevent self voting' do
    sign_in users(:editor)

    try_create_vote posts(:question_without_votes), 1

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You may not vote on your own posts.')
  end

  test 'should remove existing vote' do
    sign_in users(:editor)

    delete :destroy, params: { id: votes(:one).id }

    assert_json_success
  end

  test 'should prevent users removing others votes' do
    sign_in users(:standard_user)

    delete :destroy, params: { id: votes(:one).id }

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You are not authorized to remove this vote.')
  end

  test 'should require authentication to create a vote' do
    sign_out :user

    post :create

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You must be logged in to vote.')
  end

  test 'should require authentication to remove a vote' do
    sign_out :user

    delete :destroy, params: { id: votes(:one).id }

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You must be logged in to vote.')
  end

  test 'should prevent deleted account casting votes' do
    sign_in users(:deleted_account)

    try_create_vote posts(:question_without_votes), 1

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You must be logged in to vote.')
  end

  test 'should prevent deleted profile casting votes' do
    sign_in users(:deleted_profile)

    try_create_vote posts(:question_without_votes), 1

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You must be logged in to vote.')
  end

  test 'should not allow restricted users to vote' do
    sign_in users(:basic_user)

    try_create_vote posts(:question_without_votes), 1

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message(I18n.t('votes.limits.restricted_ability'))
  end

  private

  def try_create_vote(target_post, vote_type)
    post :create, params: { post_id: target_post.id,
                            vote_type: vote_type }
  end
end
