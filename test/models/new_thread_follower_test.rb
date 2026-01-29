require 'test_helper'

class NewThreadFollowerTest < ActiveSupport::TestCase
  test 'save succeeds with user and post' do
    new_thread_follower = NewThreadFollower.new
    new_thread_follower.user = users(:basic_user)
    new_thread_follower.post = posts(:question_one)
    assert new_thread_follower.save
  end

  test 'save fails without user' do
    new_thread_follower = NewThreadFollower.new
    new_thread_follower.post = posts(:question_one)
    assert_not new_thread_follower.save
  end

  test 'save fails without post' do
    new_thread_follower = NewThreadFollower.new
    new_thread_follower.user = users(:basic_user)
    assert_not new_thread_follower.save
  end
end
