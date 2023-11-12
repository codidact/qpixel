class DonationMailer < ApplicationMailer
  def donation_successful
    @symbol = params[:currency]
    @amount = params[:amount]
    @email = params[:email]
    @name = params[:name]
    from = "#{SiteSetting['DonationSenderName']} <#{SiteSetting['DonationSenderEmail']}>"
    reply_to = "#{SiteSetting['DonationSupportReceiverName']} <#{SiteSetting['DonationSupportReceiverEmail']}>"
    mail from: from, reply_to: reply_to, to: @email, subject: 'Thanks for your donation!'
  end

  def donation_uncaptured
    @symbol = params[:currency]
    @amount = params[:amount]
    @email = params[:email]
    @name = params[:name]
    @intent = params[:intent]
    from = "#{SiteSetting['DonationSenderName']} <#{SiteSetting['DonationSenderEmail']}>"
    reply_to = "#{SiteSetting['DonationSupportReceiverName']} <#{SiteSetting['DonationSupportReceiverEmail']}>"
    mail from: from, reply_to: reply_to, to: @email, subject: 'Your donation is unfinished - was everything okay?'
  end
end
