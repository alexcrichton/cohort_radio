#!/usr/bin/ruby

require 'gtkui.rb'
require 'pathname'
require 'ftools'
require 'bz2'

if str = Gtk.check_version(2, 4, 0)
  puts "Asami requires GTK+ 2.4.0 or later"
  puts str
  exit
end

class Object
def method_missing(name,*args)
puts "something tried to call #{name} with #{args}"
end
end
$current_path=Dir.pwd
$config_path = Pathname.new(File.expand_path("~/.Asami/config"))
begin
  File.open(File.expand_path("~/.Asami")){}
rescue
  File.mkpath(File.expand_path("~/.Asami"))
end
begin
  File.open(File.expand_path("~/.Asami/Filelists")){}
rescue
  File.mkpath(File.expand_path("~/.Asami/Filelists"))
end
begin
  File.open(File.expand_path("~/.Asami/mylists")){}
rescue
  File.mkpath(File.expand_path("~/.Asami/mylists"))
end
def load_config
  config=nil
  if $config_path.readable?
    $config_path.open("r") { |stream|
      config=YAML::load(stream)
    }
  end
  return config unless config==nil
  config={}
  config['hubs']={}
  config['default']={}
  config['nick']=ENV['USERNAME']
  config['speed']="56Kbps"
  config['interests']="nothing"
  config['active']=false
  config['useextip']=false
  config['default']['extip']=""
  config['extport']=""
  config['sharedfolders']=[]
  config['downloadtarget']=Dir.pwd
  config
end

def save_config(config)
  $config_path.open(File::CREAT|File::TRUNC|File::RDWR, 0644) { |stream|
    stream << config.to_yaml
  }
end
$DEBUG=ARGV[1]=='debug'

gui = GtkUI.new(load_config)
Gtk.timeout_add(60000){GC.start;true}
Gtk.main
