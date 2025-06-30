require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should correctly get one comment' do
    try_show_comment(comments(:one))

    assert_response(:success)
    assert_not_nil assigns(:comment)
  end

  test 'should correctly respond to the JSON format' do
    try_show_comment(comments(:one), format: :json)

    assert_response(:success)
    assert_valid_json_response
  end
end
