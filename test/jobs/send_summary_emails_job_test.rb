require 'test_helper'

class SendSummaryEmailsJobTest < ActiveJob::TestCase
  include ActionMailer::TestCase::ClearTestDeliveries

  test 'should correctly send summary emails' do
    perform_enqueued_jobs do
      SendSummaryEmailsJob.perform_later
    end

    assert_performed_jobs(2)

    delivered = SummaryMailer.deliveries.first

    to_email = users(:staff).email

    assert_equal 1, delivered.recipients.size
    assert delivered.recipients.include?(to_email),
           "Expected #{to_email} to be a recipient, actual: #{delivered.recipients.join(', ')}"
  end
end
