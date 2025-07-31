require 'active_support/core_ext/integer/time'
require 'namespaced_env_cache'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = ActiveRecord::Type::Boolean.new.cast(ENV['PERFORM_CACHING']) || false

  # Enable server timing
  config.server_timing = true

  config.log_level = ENV['LOG_LEVEL'] || :info

  # Set the cache store to the redis that was configured in the database.yml
  processed = ERB.new(File.read(Rails.root.join('config', 'database.yml'))).result(binding)
  redis_config = YAML.safe_load(processed, permitted_classes: [], permitted_symbols: [], aliases: true)["redis_#{Rails.env}"]
  config.cache_store = QPixel::NamespacedEnvCache.new(
    ActiveSupport::Cache::RedisCacheStore.new(
      **redis_config.deep_symbolize_keys.merge(reconnect_attempts: 3),
      error_handler: -> (method:, returning:, exception:) {
        Rails.logger.error("Cache error: method=#{method} returning=#{returning} exception=#{exception.message}")
      }
    )
  )

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Allow ngrok connections to dev server
  config.hosts << /[a-z0-9\-.]+\.ngrok-free\.app/

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :ses
  config.action_mailer.asset_host = 'https://meta.codidact.com'

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  config.action_mailer.delivery_method = :letter_opener_web

  config.action_mailer.default_url_options = { 
    host: 'meta.codidact.com', protocol: ENV['MAILER_PROTOCOL'] || 'https'
  }

  config.active_job.queue_adapter = :inline

  # Ensure docker ip added to allowed, given that we are in container
  if File.file?('/.dockerenv') == true
    host_ip = `/sbin/ip route|awk '/default/ { print $3 }'`.strip
    config.web_console.permissions = host_ip

    # ==> Configuration for :confirmable
    # A period that the user is allowed to access the website even without
    # confirming their account.
    days = ENV['CONFIRMABLE_ALLOWED_ACCESS_DAYS'] || '0'
    config.allow_unconfirmed_access_for = (days.to_i).days
  end

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
end
