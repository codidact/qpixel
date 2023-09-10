require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Provides a location for application-wide configuration options.
module Qpixel
  # Direct descendant of the base <tt>Rails::Application</tt>, and the overall parent class of the application.
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.autoload_paths << Rails.root.join('lib')

    config.exceptions_app = -> (env) do
      ErrorsController.action(:error).call(env)
    end

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'strings', '*.yml')]
    config.i18n.default_locale = :en

    config.to_prepare do
      Devise::Mailer.helper :users
      Devise::Mailer.layout 'devise_mailer'
    end

    console do
      require 'console_extension'
      include ConsoleExtension
    end
  end
end
