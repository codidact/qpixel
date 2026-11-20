require 'test_helper'

class DonationMailerTest < ActionMailer::TestCase
  test 'donation_successful should correctly send donation emails' do
    sender_email = SiteSetting['DonationSenderEmail']
    pi = Stripe::PaymentIntent.new.to_json
    user = users(:standard_user)

    job = DonationMailer.with(currency: '£', amount: 1000, email: user.email, name: user.username, intent: pi)
                        .donation_uncaptured
                        .deliver_later

    job.perform_now

    delivered = DonationMailer.deliveries.first

    assert_equal 1, delivered.from.length
    assert delivered.from.include?(sender_email)
  end
end
