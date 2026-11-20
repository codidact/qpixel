require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should correctly get thread content' do
    normal_two = comment_threads(:normal_two)

    try_thread_content(normal_two)

    assert_response(:success)
    assert_not_nil assigns(:comment_thread)
    assert_equal normal_two.updated_at, response.get_header('Last-Modified')
  end

  private

  def try_thread_content(thread)
    get :thread_content, params: { id: thread.id }
  end
end
