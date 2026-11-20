require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should correctly unfollow threads' do
    sign_in users(:standard_user)
    try_unfollow_thread(comment_threads(:normal))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end
end
