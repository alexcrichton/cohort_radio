require File.expand_path('../rails_extensions', __FILE__)

opts = {}

config_file = "#{Rails.root}/config/radio.yml"

if File.exists? config_file
  opts = YAML.load(ERB.new(File.read(config_file)).result)
end
opts.symbolize_keys!

Radio::DEFAULTS.merge! opts[:radio].symbolize_keys! if opts[:radio]
Radio::ProxyDaemon::DEFAULTS.merge! opts[:proxy].symbolize_keys! if opts[:proxy]

puts Radio::ProxyDaemon::DEFAULTS.inspect

ActionController::Base.class_eval { include Radio::StreamHelper }
ActionView::Base.class_eval { include Radio::StreamHelper }
