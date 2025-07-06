require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should correctly get one comment' do
    [:html, :json].each do |format|
      try_show_comment(comments(:one), format: format)

      assert_response(:success)
      assert_not_nil assigns(:comment)

      if format == :json
        assert_valid_json_response
      end
    end
  end

  test 'should correctly get one thread' do
    [:html, :json].each do |format|
      try_show_thread(comment_threads(:normal), format: format)

      assert_response(:success)
      assert_not_nil assigns(:comment_thread)
      assert_not_nil assigns(:post)

      if format == :json
        assert_valid_json_response
      end
    end
  end
end
