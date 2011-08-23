require File.expand_path('../boot', __FILE__)

# Explicitly don't load ActiveRecord
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_resource/railtie'

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, Rails.env

module CohortRadio
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    # config.i18n.default_locale = :de

    # Configure generators values. Many other options are available, be sure to check the documentation.
    # config.generators do |g|
    #   g.integration_tool :rspec
    #   g.test_framework   :rspec
    #   # g.orm             :active_record
    #   # g.template_engine :erb
    # end

    config.assets.enabled = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    config.to_prepare do
      # require 'radio'
      # require 'radio/proxy_helper'
      # require 'pusher'
      # require 'fargo/proxy_helper'
      # require 'fargo/daemon'

      # require 'drb'
      # DRb.start_service
    end
  end
end
