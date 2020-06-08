class TwoFactorMailer < ApplicationMailer
  default from: 'noreply@codidact.com'

  def disable_email
    user = params[:user]
    @host = params[:host]
    @token = SecureRandom.urlsafe_base64(64)
    user.update(login_token: @token, login_token_expires_at: 5.minutes.from_now)
    mail to: user.email, subject: 'Disable two-factor authentication on Codidact'
  end

  def login_email
    user = params[:user]
    @host = params[:host]
    @token = SecureRandom.urlsafe_base64(64)
    user.update(login_token: @token, login_token_expires_at: 5.minutes.from_now)
    mail to: user.email, subject: 'Your sign in link for Codidact'
  end
end
