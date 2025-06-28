require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerHelper

  test 'should get thread' do
    get :thread, params: { id: comment_threads(:normal).id }
    assert_response(:success)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should require auth to access high trust thread' do
    get :thread, params: { id: comment_threads(:high_trust).id }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should require privileges to access high trust thread' do
    sign_in users(:deleter)
    get :thread, params: { id: comment_threads(:high_trust).id }
    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  test 'should access thread on own deleted post' do
    sign_in users(:closer)
    get :thread, params: { id: comment_threads(:on_deleted_post).id }
    assert_response(:success)
    assert_not_nil assigns(:comment_thread)
  end
end
