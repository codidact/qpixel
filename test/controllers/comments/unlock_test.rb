require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerHelper

  test 'should correctly unlock threads' do
    sign_in users(:deleter)
    try_unlock_thread(comment_threads(:locked))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to unlock thread' do
    sign_in users(:standard_user)
    try_unlock_thread(comment_threads(:locked))

    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end
end
