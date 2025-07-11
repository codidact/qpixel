require 'test_helper'

class VotesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should cast upvote' do
    sign_in users(:standard_user)

    post :create, params: { post_id: posts(:question_without_votes).id, vote_type: 1 }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'OK', JSON.parse(response.body)['status']
  end

  test 'should cast downvote' do
    sign_in users(:standard_user)

    post :create, params: { post_id: posts(:question_without_votes).id, vote_type: -1 }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'OK', JSON.parse(response.body)['status']
  end

  test 'should return correct modified status' do
    post_id = posts(:question_without_votes).id

    sign_in users(:standard_user)

    post :create, params: { post_id: post_id, vote_type: 1 }
    post :create, params: { post_id: post_id, vote_type: -1 }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'modified', JSON.parse(response.body)['status']
  end

  test 'should silently accept duplicate votes' do
    post_id = posts(:question_without_votes).id

    sign_in users(:standard_user)

    post :create, params: { post_id: post_id, vote_type: 1 }
    post :create, params: { post_id: post_id, vote_type: 1 }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'modified', JSON.parse(response.body)['status']
  end

  test 'should prevent self voting' do
    sign_in users(:editor)

    post :create, params: { post_id: posts(:question_without_votes).id, vote_type: 1 }

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You may not vote on your own posts.')
  end

  test 'should remove existing vote' do
    sign_in users(:editor)

    delete :destroy, params: { id: votes(:one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'OK', JSON.parse(response.body)['status']
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

    post :create, params: { post_id: posts(:question_without_votes).id, vote_type: 1 }

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You must be logged in to vote.')
  end

  test 'should prevent deleted profile casting votes' do
    sign_in users(:deleted_profile)

    post :create, params: { post_id: posts(:question_without_votes).id, vote_type: 1 }

    assert_response(:forbidden)
    assert_valid_json_response
    assert_json_response_message('You must be logged in to vote.')
  end
end
