# Preview all emails at http://localhost:3000/rails/mailers/donation_mailer
class DonationMailerPreview < ActionMailer::Preview
  def donation_successful
    DonationMailer.with(symbol: '$', amount: 25.0, user: User.first).donation_successful
  end

  def donation_uncaptured
    DonationMailer.with(symbol: '£', amount: 19.5, user: User.first).donation_uncaptured
  end
end
