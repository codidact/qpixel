require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerHelper

  test 'should correctly undelete comments' do
    sign_in users(:standard_user)
    patch :undelete, params: { id: comments(:one).id }
    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require auth to undelete comments' do
    patch :undelete, params: { id: comments(:one).id }
    assert_redirected_to_sign_in
  end

  test 'should allow moderators to undelete comments' do
    sign_in users(:moderator)
    patch :undelete, params: { id: comments(:one).id }

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should not allow non-moderator users to undelete comments' do
    sign_in users(:editor)
    patch :undelete, params: { id: comments(:one).id }
    assert_response(:forbidden)
  end

  test 'only mods or admins should be able to undelete threads deleted by one of them' do
    thread = comment_threads(:normal)

    sign_in users(:moderator)
    try_delete_thread(thread)

    assert_response(:success)

    sign_in users(:deleter)
    try_undelete_thread(thread)

    assert_response(:success)
    assert_valid_json_response
    response_body = JSON.parse(response.body)
    assert_equal('error', response_body['status'])
    assert_not_nil response_body['message']

    sign_in users(:moderator)
    try_undelete_thread(thread)

    assert_response(:success)
    assert_valid_json_response
    response_body = JSON.parse(response.body)
    assert_equal('success', response_body['status'])
    assert_nil response_body['message']
  end

  test 'should correctly undelete threads' do
    sign_in users(:moderator)
    try_undelete_thread(comment_threads(:deleted))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to undelete thread' do
    sign_in users(:standard_user)
    try_undelete_thread(comment_threads(:deleted))

    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end
end
