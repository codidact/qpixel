every 1.day, at: '02:00' do
  runner 'scripts/send_subscription_emails.rb'
end

every 6.hours do
  runner 'scripts/recalc_abilities.rb'
end
