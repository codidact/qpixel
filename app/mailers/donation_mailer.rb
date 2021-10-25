class DonationMailer < ApplicationMailer
  def donation_successful
    @symbol = params[:currency]
    @amount = params[:amount]
    @email = params[:email]
    @name = params[:name]
    mail from: 'donations-support@codidact.com', reply_to: 'support@codidact.com',
         to: @email, subject: 'Thanks for your donation!'
  end

  def donation_uncaptured
    @symbol = params[:currency]
    @amount = params[:amount]
    @email = params[:email]
    @name = params[:name]
    @intent = params[:intent]
    mail from: 'donations-support@codidact.com', reply_to: 'support@codidact.com',
         to: @email, subject: "Your donation is unfinished - was everything okay?"
  end
end
