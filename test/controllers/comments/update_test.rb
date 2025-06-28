require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerHelper

  test 'should correctly update comments' do
    sign_in users(:standard_user)

    try_update_comment(comments(:one))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require auth to update comments' do
    try_update_comment(comments(:one))
    assert_redirected_to_sign_in
  end

  test 'should allow moderators to update comments' do
    sign_in users(:moderator)

    try_update_comment(comments(:one))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'non-moderator users should not be able to update comments' do
    sign_in users(:editor)
    try_update_comment(comments(:one))
    assert_response(:forbidden)
  end
end
