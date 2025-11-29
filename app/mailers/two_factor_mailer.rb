class TwoFactorMailer < ApplicationMailer
  default from: -> { "#{SiteSetting['NoReplySenderName']} <#{SiteSetting['NoReplySenderEmail']}>" }

  def disable_email
    user = params[:user]
    @host = params[:host]
    @token = SecureRandom.urlsafe_base64(64)
    user.update(login_token: @token, login_token_expires_at: 5.minutes.from_now)
    mail to: user.email, subject: "Disable two-factor authentication on #{SiteSetting['NetworkName']}"
  end

  def login_email
    user = params[:user]
    @host = params[:host]
    @token = SecureRandom.urlsafe_base64(64)
    user.update(login_token: @token, login_token_expires_at: 5.minutes.from_now)
    mail to: user.email, subject: "Your sign in link for #{SiteSetting['NetworkName']}"
  end

  def backup_code
    @user = params[:user]
    @host = params[:host]
    mail to: @user.email, subject: "Your 2FA backup code for #{SiteSetting['NetworkName']}"
  end
end
