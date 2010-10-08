Fargo.configure do |config|
  config.nick         = 'cenphol2'
  config.download_dir = Rails.root.join('tmp/fargo/downloads').to_s
end

Fargo.logger.level = ActiveSupport::BufferedLogger::DEBUG
