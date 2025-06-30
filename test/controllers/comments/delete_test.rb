require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should delete comment' do
    sign_in users(:standard_user)
    delete :destroy, params: { id: comments(:one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require auth to delete comment' do
    delete :destroy, params: { id: comments(:one).id }
    assert_redirected_to_sign_in
  end

  test 'should allow moderator to delete comment' do
    sign_in users(:moderator)
    delete :destroy, params: { id: comments(:one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should not allow other users to delete comment' do
    sign_in users(:editor)
    delete :destroy, params: { id: comments(:one).id }
    assert_response(:forbidden)
  end

  test 'should correctly delete threads' do
    sign_in users(:deleter)
    try_delete_thread(comment_threads(:normal))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to delete thread' do
    sign_in users(:standard_user)
    try_delete_thread(comment_threads(:normal))

    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end
end
