class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(User.first, 'faketoken')
  end

  def password_change
    Devise::Mailer.password_change(User.first)
  end
end
