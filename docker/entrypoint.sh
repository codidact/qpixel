#!/bin/bash

COMMUNITY_NAME=${COMMNITY_NAME:-"Dinosaur Community"}

# Give database chance to finish creation
sleep 15

# If not created yet
if [ ! -f "/db-created" ]; then
    rails db:create
    rails db:schema:load
    rails r db/scripts/create_tags_path_view.rb
    rails db:migrate
    rails db:migrate RAILS_ENV=development
    rails db:seed
    rails runner "Community.create(name: \"$COMMUNITY_NAME\", host: '0.0.0.0:3000')"
    # rails runner "User.create(username: \"$COMMUNITY_ADMIN_USERNAME\", password: \"$COMMUNITY_ADMIN_PASSWORD\", email: \"$COMMUNITY_ADMIN_EMAIL\", is_global_admin: true, is_global_moderator: true, staff: true)"
    rails runner "User.create(username: \"$COMMUNITY_ADMIN_USERNAME\", password:  Digest::SHA1.hexdigest(\"$COMMUNITY_ADMIN_PASSWORD\"), email: \"$COMMUNITY_ADMIN_EMAIL\", is_global_admin: true, is_global_moderator: true, staff: true)"
    touch /db-created
fi

# defaults to port 3000
rails server -b 0.0.0.0
