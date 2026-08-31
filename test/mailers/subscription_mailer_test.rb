require 'test_helper'

class SubscriptionMailerTest < ActionMailer::TestCase
  test 'should correctly send subscription emails' do
    all_sub = subscriptions(:all)
    post_with_html = posts(:with_sanitized_html)

    mailer = SubscriptionMailer.with(subscription: all_sub)
    email = mailer.subscription

    assert(all_sub.questions&.any? { |q| q.id == post_with_html.id })

    assert_emails 1 do
      email.deliver_later
    end

    assert email.from.include?(SiteSetting['SubscriptionSenderEmail'])
    assert email.to.include?(all_sub.user.email)
    assert email.subject.start_with?('Latest questions from your')

    assert_dom_email do
      assert_not_dom 'del'
      assert_dom 'p', /oops/
    end
  end
end
