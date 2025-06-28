require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerHelper

  test 'should get thread followers' do
    sign_in users(:admin)
    get :thread_followers, params: { id: comment_threads(:normal).id }
    assert_response(:success)
    assert_not_nil assigns(:comment_thread)
    assert_not_nil assigns(:followers)
  end

  test 'should require auth to get thread followers' do
    get :thread_followers, params: { id: comment_threads(:normal).id }
    assert_redirected_to_sign_in
  end

  test 'should require moderator to get thread followers' do
    sign_in users(:standard_user)
    get :thread_followers, params: { id: comment_threads(:normal).id }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end
end
