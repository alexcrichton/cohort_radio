#!/usr/bin/env ruby

require 'init'
Fargo::DEBUG = 1
mgmt = Fargo::Management::Server.new :port => 10090, :client => Fargo::Client.new
puts "Creating management server"
mgmt.connect

trap("TERM"){ puts 'shutting down'; mgmt.disconnect; exit }
trap("SIGINT"){ puts 'shutting down'; mgmt.disconnect; exit }
puts 'Sleeping...'
sleep 
