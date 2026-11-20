require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should archive thread' do
    sign_in users(:deleter)
    try_archive_thread(comment_threads(:normal))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to archive thread' do
    sign_in users(:standard_user)
    try_archive_thread(comment_threads(:normal))

    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end
end
