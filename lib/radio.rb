require 'playlist'
require 'queue_item'
require 'song'
require 'radio/stream'

class Radio
  
  def self.config
    return @@config if defined?(@@config)
    
    @@config = YAML.load(ERB.new(File.read("#{Rails.root}/config/radio.yml")).result)
    
    @@config.symbolize_keys!
    @@config.each_value do |v|
      v.symbolize_keys! if v.respond_to? :symbolize_keys!
    end
    
    @@config
  end
    
  attr_accessor :options
  
  def initialize options = {}
    self.options = Radio.config[:radio].merge options
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
    
    @streaming[playlist_id] = stream if !connected? || stream.connect

    true
  end
  
  def remove playlist_id
    return unless has? playlist_id
    @streaming.delete(playlist_id).disconnect
    true
  end
  
end
