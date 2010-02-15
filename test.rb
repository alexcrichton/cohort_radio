#!/usr/bin/env ruby

require 'config/environment'

radio = Playlist::Radio.new

radio.add_playlist Playlist.first

radio.connect

trap("TERM") { radio.disconnect; exit }
trap("INT") { radio.disconnect; exit }

sleep

