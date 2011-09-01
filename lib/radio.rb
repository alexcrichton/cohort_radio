require 'shout'
require 'logger'
require 'radio/stream'

class Radio

  def self.logger; @@logger end
  def self.logger= logger; @@logger = logger end
  @@logger = Logger.new STDOUT

  include ActiveSupport::Configurable

  def initialize
    @streaming = {}
  end

  def connect
    @streaming.each_value { |stream|
      stream.connect unless stream.connected?
    }
  end

  def disconnect
    @streaming.each_value { |stream|
      stream.disconnect unless stream.disconnected?
    }
  end

  def playlist_ids
    @streaming.each_value.map &:playlist_id
  end

  def next playlist_id
    return false unless has? playlist_id
    @streaming[playlist_id].next
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
    stream = Radio::Stream.new self, playlist_id
    @streaming[playlist_id] = stream if stream.connect
    true
  end

  def remove playlist_id
    return unless has? playlist_id
    @streaming.delete(playlist_id).disconnect
    true
  end

end

if ENV['RADIO_URL']
  uri = URI.parse(ENV['RADIO_URL'])
  Radio.configure do |config|
    config.user = uri.user
    config.host = uri.host
    config.port = uri.port
    config.password = uri.password
  end
end
