Fargo.configure do |config|
  config.nick         = 'cenphol2'
  config.download_dir = Rails.root.realpath.to_s + '/tmp/fargo/downloads'
end

Fargo.logger.level = ActiveSupport::BufferedLogger::DEBUG
