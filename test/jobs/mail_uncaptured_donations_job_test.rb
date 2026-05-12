require 'test_helper'

class MailUncapturedDonationsJobTest < ActiveJob::TestCase
  setup do
    WebMock.allow_net_connect!
  end

  teardown do
    WebMock.disable_net_connect!
  end

  test 'should run job successfully' do
    skip unless Stripe.api_key
    WebMock.allow_net_connect!
    perform_enqueued_jobs do
      MailUncapturedDonationsJob.perform_later
    end
    assert_performed_jobs 1
  end
end
