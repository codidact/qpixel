class StripeHelpers
  def self.secret_key
    if Rails.env.production?
      Rails.application.credentials.stripe_live_secret
    else
      Rails.application.credentials.stripe_test_secret
    end
  end

  def self.public_key
    if Rails.env.production?
      Rails.application.credentials.stripe_live_public
    else
      Rails.application.credentials.stripe_test_public
    end
  end
end

Stripe.api_key = StripeHelpers.secret_key
