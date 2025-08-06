require 'test_helper'

class PotentialSpamProfilesJobTest < ActiveJob::TestCase
  test 'should run job successfully' do
    unrestricted_id = abilities(:unrestricted).internal_id

    assert users(:spammer).community_user.ability?(unrestricted_id)

    perform_enqueued_jobs do
      PotentialSpamProfilesJob.perform_later
    end

    assert_performed_jobs 1
    assert_not users(:spammer).community_user.ability?(unrestricted_id)
  end
end
