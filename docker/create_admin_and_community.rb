# 1. Create the community
community_name = ENV['COMMUNITY_NAME'] || 'Dinosaur Community'
Community.create(name: community_name, host: "localhost:#{ENV['LOCAL_DEV_PORT']}")

# 2. Create the admin user, ensure doesn't require confirmation
username = ENV['COMMUNITY_ADMIN_USERNAME'] || 'admin'
password = ENV['COMMUNITY_ADMIN_PASSWORD'] || 'password'
email = ENV['COMMUNITY_ADMIN_EMAIL'] || 'codadict@noreply.com'

User.create(username: username, password: password, email: email, is_global_admin: true, is_global_moderator: true,
            staff: true)
# You'll need to manually set confirmation for this user
# $ docker exec qpixel_uwsgi_1 rails runner "User.second.update(confirmed_at: DateTime.now)"
