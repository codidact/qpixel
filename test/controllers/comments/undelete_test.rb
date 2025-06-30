require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should correctly undelete comments' do
    sign_in users(:standard_user)
    try_undelete_comment(comments(:deleted))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require auth to undelete comments' do
    try_undelete_comment(comments(:deleted))
    assert_redirected_to_sign_in
  end

  test 'should allow moderators to undelete comments' do
    sign_in users(:moderator)
    try_undelete_comment(comments(:deleted))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should not allow non-moderator users to undelete comments' do
    sign_in users(:editor)
    try_undelete_comment(comments(:deleted))
    assert_response(:forbidden)
  end

  test 'comment undeletion should correctly handle validation' do
    sign_in users(:moderator)

    comment = comments(:deleted)

    # this is a bit cursed, but IIRC the easiest way to test this
    comment.stub(:update, false) do
      Comment.stub(:unscoped, Comment) do
        Comment.stub(:find, comment) do
          try_undelete_comment(comment)

          assert_response(:internal_server_error)
        end
      end
    end
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
