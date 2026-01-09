require 'test_helper'

class CleanUpThreadFollowersJobTest < ActiveJob::TestCase
  test 'should correctly clean up thread followers' do
    thread = comment_threads(:without_followers)
    std_usr = users(:standard_user)

    ThreadFollower.create(comment_thread: thread, user: std_usr)
    ThreadFollower.create(comment_thread: thread, user: std_usr)
    assert_equal 2, ThreadFollower.where(comment_thread: thread, user: std_usr).size

    perform_enqueued_jobs do
      CleanUpThreadFollowersJob.perform_later
    end

    assert_performed_jobs 1
    assert_equal 1, ThreadFollower.where(comment_thread: thread, user: std_usr).size
  end
end
