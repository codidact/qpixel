require 'test_helper'
require 'comments_test_helpers'

class CommentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include CommentsControllerTestHelpers

  test 'should lock thread indefinitely by default' do
    sign_in users(:deleter)
    try_lock_thread(comment_threads(:normal))

    @thread = assigns(:comment_thread)

    assert_response(:found)
    assert_not_nil @thread
    assert_redirected_to comment_thread_path(@thread)
    assert_equal true, @thread.locked
  end

  test 'should lock thread for a specific duration if provided' do
    sign_in users(:deleter)
    try_lock_thread(comment_threads(:normal), duration: 2)

    @thread = assigns(:comment_thread)

    assert_not_nil @thread
    assert @thread.lock_active?
    travel_to 3.days.from_now
    assert_not @thread.lock_active?
  end

  test 'should require privilege to lock thread' do
    sign_in users(:standard_user)
    try_lock_thread(comment_threads(:normal))

    assert_response(:not_found)
    assert_not_nil assigns(:comment_thread)
  end
end
