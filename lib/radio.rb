require 'playlist'
require 'queue_item'

class Radio
    
  DEFAULTS = {:user => 'source', :password => 'hackme', :host => 'localhost', :port => 8000}
  
  attr_accessor :options
  
  def initialize options = {}
    self.options = DEFAULTS.merge options
    @streaming = {}
    @connected = false
  end
  
  def connect
    @streaming.each_value { |stream| stream.connect }
    @connected = true
  end
  
  def disconnect
    @streaming.each_value { |stream| stream.disconnect }
    @connected = false
  end
  
  def connected?
    @connected
  end
  
  def playlists
    @streaming.each_value.map &:playlist
  end
  
  def next playlist
    return false unless has? playlist
    @streaming[playlist.slug].next
  end
  
  def playing? playlist
    return false unless has? playlist
    @streaming[playlist.slug].playing?
  end
    
  def has? playlist
    @streaming.has_key? playlist.slug
  end
  
  def add playlist
    return if @streaming[playlist.slug]
    stream = Radio::Stream.new options.merge(:playlist => playlist)
    @streaming[playlist.slug] = stream      
    stream.connect if @connected
    true
  end
  
  def remove playlist
    return unless @streaming.has_key? playlist.slug
    @streaming.delete(playlist.slug).disconnect
  end
  
end
