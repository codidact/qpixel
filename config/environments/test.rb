require 'active_support/core_ext/integer/time'
require 'namespaced_env_cache'

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Turn false under Spring and add config.action_view.cache_template_loading = true.
  config.cache_classes = false
  config.action_view.cache_template_loading = true

  config.log_level = :info

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

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

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  config.action_mailer.default_url_options = { 
    host: 'test.host',
    protocol: ENV['MAILER_PROTOCOL'] || 'https'
  }

  config.active_job.queue_adapter = :inline

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true
  
  # Don't colorize logs - we are writing to log files directly
  config.colorize_logging = false
end
