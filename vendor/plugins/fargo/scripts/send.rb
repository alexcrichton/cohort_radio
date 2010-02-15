#!/usr/bin/env ruby

require 'init'

puts Fargo::Management::Client.new(:port => 10090).send(*ARGV).inspect
