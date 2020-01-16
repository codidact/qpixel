# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SubscriptionMailerPreview < ActionMailer::Preview
  def subscription
    SubscriptionMailer.with(subscription: Subscription.first).subscription
  end
end
