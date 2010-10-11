Fargo.configure do |config|
  config.nick           = 'fargo'
  config.download_dir   = Rails.root.join('tmp/fargo/downloads').realpath
  config.config_dir     = Rails.root.join('tmp/fargo/config').realpath
  config.websocket_host = '0.0.0.0'
end

Fargo.logger.level = ActiveSupport::BufferedLogger::DEBUG
