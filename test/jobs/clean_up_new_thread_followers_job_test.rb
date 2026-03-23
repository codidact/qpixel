require 'test_helper'

class CleanUpNewThreadFollowersJobTest < ActiveJob::TestCase
  test 'should correctly clean up new thread followers' do
    post = posts(:without_new_thread_followers)
    std_usr = users(:standard_user)

    NewThreadFollower.create(post: post, user: std_usr)
    NewThreadFollower.create(post: post, user: std_usr)
    assert_equal 2, NewThreadFollower.where(post: post, user: std_usr).size

    perform_enqueued_jobs do
      CleanUpNewThreadFollowersJob.perform_later
    end

    assert_performed_jobs 1
    assert_equal 1, NewThreadFollower.where(post: post, user: std_usr).size
  end
end
