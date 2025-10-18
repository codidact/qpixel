require 'test_helper'

class AutoCloseComplaintsJobTest < ActiveJob::TestCase
  test 'complaints auto closure works' do
    perform_enqueued_jobs do
      AutoCloseComplaintsJob.perform_later
    end

    assert_equal 'closed', complaints(:old_reviewed).status
  end
end
