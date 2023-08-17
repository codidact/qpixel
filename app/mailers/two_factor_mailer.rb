class TwoFactorMailer < ApplicationMailer
  default from: 'Codidact <noreply@codidact.com>'

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

  def backup_code
    @user = params[:user]
    @host = params[:host]
    mail to: @user.email, subject: 'Your 2FA backup code for Codidact'
  end
end
