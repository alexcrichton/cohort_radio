#!/usr/bin/ruby

require File.expand_path('../../config/environment',  __FILE__)

require 'shout'
# require 'mp3info'
require 'iconv'

BLOCKSIZE = 1 << 16

class Stream < Shout

  def initialize(host, port, user, password)
    super
    self.host = host
    self.port = port unless port.nil?
    self.user = user unless user.nil?
    self.pass = password unless password.nil?
    @tag_recoder = Iconv.new("utf-8", 'windows-1251')
  end

  def play_song song
    # unless File.exists?(filename) then
    #   Rails.logger.debug "File '#{filename}' don't exists."
    #   @error_count += 1
    #   Rails.logger.debug "Already was #{@error_count} errors"
    #   return
    # end
    
    raise 'Stream is not connected to server' unless connected?
       
    set_metadata_from_song song
    
    puts "Playing file '#{song.audio.path}'..."

    File.open(song.audio.path) do |file|
      while data = file.read(BLOCKSIZE)
      	self.send data
      	puts "Block sent."
      	self.sync
      end
    end
  end

  def set_metadata_from_song song
    
    return unless self.format == Shout::MP3
    
    m = ShoutMetadata.new
    m.add 'filename', song.audio.path
    m.add 'song', @tag_recoder.iconv("#{song.title} (#{song.artist} - #{song.album})")
      
    self.metadata = m
  end

end

########################################
#### THIS WORKS FOR STREAMING A FILE!
########################################
p = Playlist.find_by_slug 'main'
song = p.songs.first
s = Stream.new('eve.alexcrichton.com', 8000, 'source', 'mightiest550@tendentiousness')
s.mount = "/#{p.slug}"
# s.public = true
s.name = p.name
s.description = p.description || ''
s.format = Shout::MP3

trap("TERM") { s.disconnect; exit }
trap("INT") { s.disconnect; exit }

s.connect

begin 
  while true
    s.play_song song 
    sleep 10
  end
ensure
  s.disconnect
end
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
