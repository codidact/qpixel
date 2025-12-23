every 1.day, at: '02:00' do
  runner 'scripts/send_subscription_emails.rb'
end

every 1.day, at: '02:05' do
  runner 'scripts/mail_uncaptured_donations.rb'
end

every 1.day, at: '02:10' do
  runner 'scripts/prune_email_logs.rb'
end

every 1.day, at: '02:15' do
  runner 'scripts/run_spam_cleanup.rb'
end

every 1.day, at: '02:20' do
  runner 'scripts/cleanup_drafts.rb'
end

every 1.day, at: '02:25' do
  runner 'scripts/cleanup_votes.rb'
end

every 1.day, at: '02:30' do
  runner 'scripts/run_complaints_closure.rb'
end

every 7.days, at: '02:35' do
  runner 'scripts/run_thread_followers_cleanup.rb'
end

every 6.hours do
  runner 'scripts/recalc_abilities.rb'
end

every 30.minutes do
  runner 'scripts/run_summary_mailer.rb'
end
