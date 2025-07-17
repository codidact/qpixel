require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should get pingable users on thread' do
    sign_in users(:standard_user)

    try_pingable(posts(:question_one))

    assert_response(:success)
    assert_valid_json_response
  end

  private

  # @param post [Post]
  def try_pingable(post)
    get :pingable, params: { id: -1, post: post.id }
  end
end
