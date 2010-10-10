Fargo.configure do |config|
  config.nick         = 'cenphol2'
  config.download_dir = Rails.root.realpath.to_s + '/tmp/fargo/downloads'
  config.config_dir   = Rails.root.realpath.to_s + '/tmp/fargo/config'
  config.websocket_host = '0.0.0.0'
end

Fargo.logger.level = ActiveSupport::BufferedLogger::DEBUG
