require 'test_helper'

class VotesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should cast upvote' do
    sign_in users(:standard_user)
    post :create, params: { post_id: posts(:question_two).id, vote_type: 1 }
    assert_equal 'OK', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test 'should cast downvote' do
    sign_in users(:standard_user)
    post :create, params: { post_id: posts(:question_two).id, vote_type: -1 }
    assert_equal 'OK', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test 'should return correct modified status' do
    sign_in users(:editor)
    post :create, params: { post_id: posts(:question_one).id, vote_type: -1 }
    assert_equal 'modified', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test 'should silently accept duplicate votes' do
    sign_in users(:editor)
    post :create, params: { post_id: posts(:question_one).id, vote_type: 1 }
    assert_equal 'modified', JSON.parse(response.body)['status']
    assert_response 200
  end

  test 'should prevent self voting' do
    sign_in users(:editor)
    post :create, params: { post_id: posts(:question_two).id, vote_type: 1 }
    assert_equal 'You may not vote on your own posts.', JSON.parse(response.body)['message']
    assert_response(403)
  end

  test 'should remove existing vote' do
    sign_in users(:editor)
    delete :destroy, params: { id: votes(:one).id }
    assert_equal 'OK', JSON.parse(response.body)['status']
    assert_response(200)
  end

  test 'should prevent users removing others votes' do
    sign_in users(:standard_user)
    delete :destroy, params: { id: votes(:one).id }
    assert_equal 'You are not authorized to remove this vote.', JSON.parse(response.body)['message']
    assert_response(403)
  end

  test 'should require authentication to create a vote' do
    sign_out :user
    post :create
    assert_equal 'You must be logged in to vote.', JSON.parse(response.body)['message']
    assert_response(403)
  end

  test 'should require authentication to remove a vote' do
    sign_out :user
    delete :destroy, params: { id: votes(:one).id }
    assert_equal 'You must be logged in to vote.', JSON.parse(response.body)['message']
    assert_response(403)
  end
end
