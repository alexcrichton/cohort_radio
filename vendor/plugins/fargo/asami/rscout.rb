
require 'socket'
require 'monitor.rb'
require 'thread.rb'
require 'pathname'
require 'yaml'

require 'util.rb'
require 'key_generator.rb'
require 'dc_connection.rb'
require 'hub_connection.rb'
require 'client_connection.rb'
require 'active_client_connection.rb'
require 'ui.rb'
require 'command_line_ui.rb'

$config_path = Pathname.new(File.expand_path("~/.rscout/config"))

def load_config
  if $config_path.readable?
    $config_path.open("r") { |stream|
      YAML::load stream
    }
  else
    $stderr.puts "you don't have a config, please get one"
    exit
  end
end

def save_config(config)
  $config_path.open(File::CREAT|File::TRUNC|File::RDWR, 0644) { |stream|
    stream << config.to_yaml
  }
end

def scout
  Thread.abort_on_exception = true
  gui = CommandLineUI.new load_config
#  gui.connect 'localhost', 411
  gui.run
end

scout

