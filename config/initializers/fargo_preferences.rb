require 'fargo'
require 'fargo/proxy_helper'

opts = YAML.load(ERB.new(File.read("#{Rails.root}/config/fargo.yml")).result)

opts.symbolize_keys!

Fargo::Client::DEFAULTS.merge! opts[:client].symbolize_keys!
Rails.logger.level = opts[:logger_level] if opts[:logger_level]

ActionController::Base.class_eval { include Fargo::ProxyHelper }
ActionView::Base.class_eval       { include Fargo::ProxyHelper }
