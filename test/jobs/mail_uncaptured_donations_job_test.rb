require "test_helper"

class MailUncapturedDonationsJobTest < ActiveJob::TestCase
  test 'should run job successfully' do
    perform_enqueued_jobs do
      MailUncapturedDonationsJob.perform_later
    end
    assert_performed_jobs 1
  end
end
