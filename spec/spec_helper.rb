# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each{ |f| require f }

  CarrierWave.configure do |config|
    config.cache_dir = 'tmp/carrierwave/cache'
    config.store_dir = 'tmp/carrierwave/store'
    config.storage = :file
    config.enable_processing = false
  end

  RSpec.configure do |config|
    config.mock_with :rspec

    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.orm = "mongoid"
    end

    config.after(:suite) do
      # Remove all cached files created at any point
      CarrierWave::Uploader::Base.clean_cached_files! 0
    end

    config.before(:each) do
      DatabaseCleaner.clean
    end
  end
end
