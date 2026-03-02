class MailUncapturedDonationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    intents = Stripe::PaymentIntent.list
    mailed = 0
    errors = 0
    intents.auto_paging_each do |pi|
      begin
        break unless Time.at(pi.created) >= 24.hours.ago
        next unless pi.status == 'requires_payment_method'
        next unless pi.metadata['user_id'].present?
        next if pi.metadata['emailed'].present?
        user = User.find(pi.metadata['user_id'])
        symbol = { 'GBP' => '£', 'USD' => '$', 'EUR' => '€' }[pi.currency.upcase]
        amount = pi.amount / 100
        DonationMailer.with(currency: symbol, amount: amount, email: user.email, name: user.username, intent: pi)
                      .donation_uncaptured.deliver_now
        Stripe::PaymentIntent.update(pi.id, { metadata: { emailed: true } })
        logger.debug "Mailed ##{user.id} for PaymentIntent #{pi.id}"
        mailed += 1
      rescue => ex
        Stripe::PaymentIntent.update(pi.id, { metadata: { email_error: "#{ex.message}" } })
        logger.error "Error sending email for user #{user.id}, PaymentIntent #{pi.id}: #{ex.message}"
        errors += 1
      end
    end
    logger.info "Mailed #{mailed} donations, #{errors} errors"
  end
end
