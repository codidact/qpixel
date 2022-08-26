Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Set the cache store to the redis that was configured in the database.yml
  processed = ERB.new(File.read(Rails.root.join('config', 'database.yml'))).result(binding)
  redis_config = YAML.safe_load(processed, [], [], true)["redis_#{Rails.env}"]
  config.cache_store = :redis_cache_store, {
    url: "redis://#{redis_config['host']}:#{redis_config['port']}"
  }

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :ses
  config.action_mailer.asset_host = 'https://meta.codidact.com'
  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

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
  # config.action_view.raise_on_missing_translations = true

  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.default_url_options = { host: 'meta.codidact.com', protocol: 'https' }

  # Ensure docker ip added to allowed, given that we are in container
  if File.file?('/.dockerenv') == true
    host_ip = `/sbin/ip route|awk '/default/ { print $3 }'`.strip
    config.web_console.allowed_ips << host_ip

    # ==> Configuration for :confirmable
    # A period that the user is allowed to access the website even without
    # confirming their account.
    days = ENV['CONFIRMABLE_ALLOWED_ACCESS_DAYS'] || '0'
    config.allow_unconfirmed_access_for = (days.to_i).days
  end

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
