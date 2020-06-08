# Preview all emails at http://localhost:3000/rails/mailers/two_factor_mailer
class TwoFactorMailerPreview < ActionMailer::Preview
  def disable_email_preview
    TwoFactorMailer.with(user: User.last, host: 'testhost.codidact.com').disable_email
  end

  def login_email_preview
    TwoFactorMailer.with(user: User.last, host: 'testhost.codidact.com').login_email
  end
end
