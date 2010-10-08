module Radio
  # This is a funny name, see this http://goo.gl/qXGW for why.
  class Giraffe

    include ActiveSupport::Configurable

    def initialize
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
      stream = Radio::Stream.new self, playlist_id

      @streaming[playlist_id] = stream if !connected? || stream.connect

      true
    end

    def remove playlist_id
      return unless has? playlist_id
      @streaming.delete(playlist_id).disconnect
      true
    end

  end
end
