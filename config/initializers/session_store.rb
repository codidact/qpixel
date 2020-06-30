# Be sure to restart your server when you modify this file.

if Rails.env.production?
  Rails.application.config.session_store :cookie_store, key: 'codidact_acct', domain: :all
else
  Rails.application.config.session_store :cookie_store, key: 'codidact_acct'
end
