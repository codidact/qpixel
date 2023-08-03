User.where(enabled_2fa: true).each do |user|
  user.update(backup_2fa_code: SecureRandom.alphanumeric(24))
  TwoFactorMailer.with(user: user, host: 'meta.codidact.com').backup_code.deliver_later
end
