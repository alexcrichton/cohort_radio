require 'playlist'
require 'queue_item'
require 'song'

class Radio
  
  DEFAULTS = YAML.load_file("#{Rails.root}/config/radio.yml")['radio'].symbolize_keys! unless defined?(DEFAULTS)
  
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
  
  def current_song playlist
    return false unless has? playlist
    @streaming[playlist.slug].current_song
  end
    
  def has? playlist
    @streaming.has_key? playlist.slug
  end
  
  def add playlist
    return if has? playlist
    stream = Radio::Stream.new options.merge(:playlist => playlist)
    @streaming[playlist.slug] = stream      
    stream.connect if @connected
    true
  end
  
  def remove playlist
    return unless has? playlist
    @streaming.delete(playlist.slug).disconnect
    true
  end
  
end
