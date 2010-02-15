#!/usr/bin/env ruby

require 'init'
require 'fargo/test'
Thread.abort_on_exception = true
# c = Fargo::Client.new :hub_port => 7314, :hub_address => '127.0.0.1', :search_port => 7315, :active_port => 7316, :nick => 'cenphol2', :passive => true
# 
# c.connect
# sleep 10
# c.disconnect

Fargo::Test.new.run
# require 'rubygems'
# require 'ncurses'
# require 'readline'
# Ncurses.initscr
# Ncurses.cbreak
# Ncurses.noecho
# Ncurses.nonl
# 
# # Ncurses.stdscr.keypad true
# # puts Ncurses.ROWS
# scr = Ncurses.stdscr
# # Ncurses.LINES.times{ |i| scr.move(i, 3); scr.addstr("move(#{i}, 3)"); scr.refresh; sleep 1 }
# loop {
#   scr.move(Ncurses.LINES, 3)
#   scr.refresh
#   Readline.readline("prompt> ", true)
# }
# sleep 1
# 
# # Ncurses.doupdate
# # window     = Ncurses.stdscr
# window.move(5,10)
# window.addstr('awefawefwaef')
# scr = window
# scr.clear() # clear screen
# scr.move(5,5) # move cursor
# scr.addstr("move(5,5)")
# scr.refresh() # update screen
# sleep(2)
# scr.move(2,2)
# scr.addstr("move(2,2)")
# scr.refresh()
# sleep(2)
# scr.move(10, 2)
# scr.addstr("Press a key to continue")
# scr.getch()
# 
# Ncurses.doupdate
# sleep 3

# require 'readline'
# puts Readline.readline('asdf> ', true)