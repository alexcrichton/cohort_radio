Fargo.configure do |config|
  config.nick         = 'cenphol2'
  config.download_dir = Rails.root.realpath.to_s + '/tmp/fargo/downloads'
  config.config_dir   = Rails.root.realpath.to_s + '/tmp/fargo/config'
end

Fargo.logger.level = ActiveSupport::BufferedLogger::DEBUG
