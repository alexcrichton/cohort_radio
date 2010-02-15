require 'fargo'

opts = YAML.load_file "#{Rails.root}/config/fargo.yml"
opts.symbolize_keys!
opts[:client][:download_dir] = "#{Rails.root}/tmp/fargo/downloads"
FileUtils.mkdir_p opts[:client][:download_dir] unless File.directory? opts[:client][:download_dir]

Fargo::Client::DEFAULTS.merge! opts[:client].symbolize_keys! if opts[:client]
Fargo.logger.level = opts[:logger_level] if opts[:logger_level]

Radio::FargoDaemon::DEFAULTS.merge! opts[:proxy].symbolize_keys! if opts[:proxy]

ActionController::Base.class_eval { include Radio::FargoHelper }
ActionView::Base.class_eval { include Radio::FargoHelper }
