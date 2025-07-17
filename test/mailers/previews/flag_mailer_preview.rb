# Preview all emails at http://localhost:3000/rails/mailers/flag_mailer
class FlagMailerPreview < ActionMailer::Preview
  def flag_escalated
    FlagMailer.with(flag: Flag.escalated.last || Flag.last).flag_escalated
  end
end
