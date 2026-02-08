require 'test_helper'

class ThreadFollowerTest < ActiveSupport::TestCase
  test 'save succeeds with user and thread' do
    new_thread_follower = ThreadFollower.new
    new_thread_follower.user = users(:basic_user)
    new_thread_follower.comment_thread = comment_threads(:normal)
    assert new_thread_follower.save
  end

  test 'save fails without user' do
    new_thread_follower = ThreadFollower.new
    new_thread_follower.comment_thread = comment_threads(:normal)
    assert_not new_thread_follower.save
  end

  test 'save fails without thread' do
    new_thread_follower = ThreadFollower.new
    new_thread_follower.user = users(:basic_user)
    assert_not new_thread_follower.save
  end
end
