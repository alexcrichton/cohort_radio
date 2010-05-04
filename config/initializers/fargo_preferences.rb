require 'fargo'

opts = YAML.load(ERB.new(File.read("#{Rails.root}/config/fargo.yml")).result)

opts.symbolize_keys!
opts[:client].symbolize_keys!

FileUtils.mkdir_p opts[:client][:download_dir] unless File.directory? opts[:client][:download_dir]

Fargo::Client::DEFAULTS.merge! opts[:client].symbolize_keys! if opts[:client]
Fargo.logger.level = opts[:logger_level] if opts[:logger_level]

ActionController::Base.class_eval { include Fargo::ProxyHelper }
ActionView::Base.class_eval       { include Fargo::ProxyHelper }
