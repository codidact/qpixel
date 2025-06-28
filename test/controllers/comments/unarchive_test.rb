require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerHelper

  test 'should unarchive thread' do
    sign_in users(:deleter)
    try_unarchive_thread(comment_threads(:archived))

    assert_response(:success)
    assert_valid_json_response
    assert_equal 'success', JSON.parse(response.body)['status']
  end

  test 'should require privilege to unarchive thread' do
    sign_in users(:standard_user)
    try_unarchive_thread(comment_threads(:archived))

    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end

  private

  # @param thread [CommentThread]
  def try_unarchive_thread(thread)
    post :thread_unrestrict, params: { id: thread.id, type: 'archive' }
  end
end
