require 'active_support/core_ext/integer/time'
require 'namespaced_env_cache'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = Terser.new
  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on Amazon S3 (see config/storage.yml for options).
  config.active_storage.service = :s3

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [ :subdomain, :uuid ]

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

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "qpixel_production"

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  config.action_mailer.delivery_method = :ses
  config.action_mailer.default_url_options = { 
    host: 'meta.codidact.com',
    protocol: ENV['MAILER_PROTOCOL'] || 'https'
  }
  config.action_mailer.asset_host = 'https://meta.codidact.com'

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.active_job.queue_adapter = :async
end
