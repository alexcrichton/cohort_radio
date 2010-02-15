#!/usr/bin/env ruby

require '../init'

client = Fargo::Client.new

puts 'Connecting...'
client.connect
client.hub.subscribe { |type, map|
  puts "RESULT: #{map[:nick]} #{map[:path].inspect}" if map.is_a?(Hash) && map[:type] == :passive_search_result && map[:openslots] > 0
}
sleep 5
puts "Searching for: #{ARGV.join ' '}"
client.search_hub Fargo::Search.new(:query => ARGV.join(' '))
sleep 5
client.disconnect
