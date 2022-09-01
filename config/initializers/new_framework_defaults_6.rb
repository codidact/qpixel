# Once these settings are set to their new default values, rolling back to an
# older version of rails becomes much harder, because the old rails is not
# compatible with the new cookies/urls.
#
# Once the application is stable with this version of the system, comment all
# lines below (or remove this file) to switch to the rails 6.1 settings.

# Embed purpose and expiry metadata inside signed and encrypted
# cookies for increased security.
#
# This option is not backwards compatible with earlier Rails versions.
Rails.application.config.action_dispatch.use_cookies_with_metadata = false

# Specify cookies SameSite protection level: either :none, :lax, or :strict.
#
# This change is not backwards compatible with earlier Rails versions.
Rails.application.config.action_dispatch.cookies_same_site_protection = nil

# Generate CSRF tokens that are encoded in URL-safe Base64.
#
# This change is not backwards compatible with earlier Rails versions.
Rails.application.config.action_controller.urlsafe_csrf_tokens = false