require 'test_helper'

class CleanUpSpammyUsersJobTest < ActiveJob::TestCase
  test 'should correctly clean up spammy users' do
    spammer = users(:spammer)

    assert_not spammer.deleted?

    perform_enqueued_jobs do
      CleanUpSpammyUsersJob.perform_later
    end

    assert_performed_jobs 1
    spammer.reload

    assert spammer.deleted?
    assert spammer.deleted_by.same_as?(User.system)
  end
end
