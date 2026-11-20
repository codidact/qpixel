require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should delete comment' do
    sign_in users(:standard_user)

    try_delete_comment(comments(:one), format: :json)

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require auth to delete comment' do
    [:html, :json].each do |format|
      try_delete_comment(comments(:one), format: format)

      if format == :html
        assert_redirected_to_sign_in
      else
        assert_response(:unauthorized)
        assert_valid_json_response
      end
    end
  end

  test 'should allow moderators to delete comments' do
    sign_in users(:moderator)

    try_delete_comment(comments(:one), format: :json)

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should not allow other users to delete comment' do
    sign_in users(:editor)
    try_delete_comment(comments(:one))

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
