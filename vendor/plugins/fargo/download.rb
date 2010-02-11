#!/usr/bin/env ruby

require 'init'
require 'rubygems'
require 'ncurses'

Ncurses.initscr

def set_progress percent
  screen = Ncurses.stdscr
  @output.each_with_index { |str, i| screen.move(2 + i, 2); screen.addstr(str) }
  screen.move 2 + @output.length, 2
  screen.addstr sprintf("Downloaded:\t\t%10f%%\n", percent * 100) if percent > 0
  screen.refresh
end
@output = []

client = Fargo::Client.new

@thread = Thread.current

@output << 'Connecting...'
set_progress 0
client.connect
client.hub.subscribe { |map|
  if map.is_a? Hash
    if map[:type] == :download_progress
      set_progress map[:percent]
    elsif map[:type] == :download_finished
      set_progress 1
      @thread.wakeup
    end
  end
}
sleep 5
@output << "Downloading '#{ARGV[1]}' from: #{ARGV[0]}"
set_progress 0
client.download ARGV[0], ARGV[1]
# puts "Hit Ctrl+C when done"
# trap('SIGINT') { client.disconnect; exit }
sleep 
Ncurses.endwin 