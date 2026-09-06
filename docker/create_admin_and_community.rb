community_name = ENV.fetch('COMMUNITY_NAME', nil)
username = ENV.fetch('COMMUNITY_ADMIN_USERNAME', nil)
password = ENV.fetch('COMMUNITY_ADMIN_PASSWORD', nil)
email = ENV.fetch('COMMUNITY_ADMIN_EMAIL', nil)
port = ENV.fetch('LOCAL_DEV_PORT', '3000')

unless [community_name, username, password, email].all?(&:present?)
  puts 'COMMUNITY_NAME is required' unless community_name.present?
  puts 'COMMUNITY_ADMIN_USERNAME is required' unless username.present?
  puts 'COMMUNITY_ADMIN_PASSWORD is required' unless password.present?
  puts 'COMMUNITY_ADMIN_EMAIL is required' unless email.present?
  exit 1
end

# 1. Create the community
Community.create!(name: community_name, host: "localhost:#{port}")
Rails.cache.clear

# 2. Create the admin user, ensure doesn't require confirmation
User.create!(username: username,
             password: password,
             email: email,
             is_global_admin: true,
             is_global_moderator: true,
             staff: true,
             confirmed_at: DateTime.now)
