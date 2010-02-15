#!/usr/bin/env ruby

require '../init'
mgmt = Fargo::Management::Server.new :port => 10091, :client => Fargo::Client.new
puts "Creating management server"
mgmt.connect

trap("TERM"){ puts 'shutting down'; mgmt.disconnect; exit }
trap("SIGINT"){ puts 'shutting down'; mgmt.disconnect; exit }
puts 'Sleeping...'
sleep 
