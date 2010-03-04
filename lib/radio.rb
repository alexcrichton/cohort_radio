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
  
  def playlist_ids
    @streaming.each_value.map &:playlist_id
  end
  
  def next playlist_id
    return false unless has? playlist_id
    @streaming[playlist_id].next
  end
  
  def playing? playlist_id
    return false unless has? playlist_id
    @streaming[playlist_id].playing?
  end
  
  def current_song playlist_id
    return false unless has? playlist_id
    @streaming[playlist_id].current_song
  end
    
  def has? playlist_id
    @streaming.has_key? playlist_id
  end
  
  def add playlist_id
    return if has? playlist_id
    stream = Radio::Stream.new options.merge(:playlist_id => playlist_id)
    @streaming[playlist_id] = stream      
    stream.connect if @connected
    true
  end
  
  def remove playlist_id
    return unless has? playlist_id
    @streaming.delete(playlist_id).disconnect
    true
  end
  
end
