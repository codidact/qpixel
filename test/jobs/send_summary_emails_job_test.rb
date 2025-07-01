require 'test_helper'

class SendSummaryEmailsJobTest < ActiveJob::TestCase
  test 'should correctly send summary emails' do
    perform_enqueued_jobs do
      SendSummaryEmailsJob.perform_later
    end

    assert_performed_jobs(2)

    staff_mail = SummaryMailer.deliveries.first

    assert_equal 1, staff_mail.recipients.size
    assert staff_mail.recipients.include?(users(:staff).email)
  end
end
