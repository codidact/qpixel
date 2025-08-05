require 'test_helper'

class PotentialSpamProfilesJobTest < ActiveJob::TestCase
  test 'should run job successfully' do
    perform_enqueued_jobs do
      PotentialSpamProfilesJob.perform_later
    end
    assert_performed_jobs 1
  end
end
