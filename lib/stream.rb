#!/usr/bin/ruby

#--
#
# $Id: stream.rb,v 1.2 2005/10/11 07:21:31 jek Exp $
#
# Copyright (c) 2000, Yauhen Kharuzhy <jekhor@gmail.com>
#
# This file is part of RIces
#
# RIces is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
# require 'shout'
# require 'mp3info'
# require 'iconv'

BLOCKSIZE = 65536

class Stream < Shout

  def initialize(host, port, user, password)
    
    super()
    self.host = host
    self.port = port unless port.nil?
    self.user = user unless user.nil?
    self.pass = password unless password.nil?
    @error_count = 0
    @tag_recoder = Iconv.new("utf-8", 'windows-1251')
  end

  def play_file(filename)
    unless File.exists?(filename) then
      Rails.logger.debug "File '#{filename}' don't exists."
      @error_count += 1
      Rails.logger.debug "Already was #{@error_count} errors"
      return
    end
    
    raise 'Stream is not connected to server' unless connected?
   
    @error_count = 0
    
    set_metadata_from_file(@current_filename) if @format == Shout::MP3
    
    Signal.trap("TERM") { exit }
    
    Rails.logger.debug "Playing file '#{filename}'..."
    
    File.open(filename) do |file|
      while data = file.read(BLOCKSIZE)
      	self.send data
      	Rails.logger.debug "Block sent."
      	self.sync
      end
    end
  end

  def set_metadata_from_file(filename)
    
    return unless self.format == Shout::MP3
    
    m = ShoutMetadata.new
    if Mp3Info.hastag1?(filename)
      t = Mp3Info.new(filename).tag
      m.add("song", @tag_recoder.iconv("#{t['artist']} (#{t['album']}) - #{t['title']}"))
    else
      m.add("song", File.basename(filename, File.extname(filename)))
    end
    set_metadata(m)
  end

end

########################################
#### THIS WORKS FOR STREAMING A FILE!
########################################
# if $0 == __FILE__
#   s = Stream.new(0, '128.2.152.87', 8000, 'source', 'mightiest550@tendentiousness')
#   s.mount = "/rices"
#   s.public = true
#   s.format = Shout::MP3
#   s.open
#   begin
#     trap("INT") {s.close; exit}
#     while true; s.play_file(ARGV[0]); sleep 10; end
#   ensure
#     s.close
#   end
# end
