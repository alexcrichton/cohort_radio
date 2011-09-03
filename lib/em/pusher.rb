require 'pusher'
require 'libwebsocket'
require 'json'
require 'hmac-sha2'

module EventMachine
  module PusherSocket

    def self.uri= uri; @@uri = uri; end

    def post_init
      url = @@uri.to_s
      url << '?client=js&version=1.9.3'
      @hs = LibWebSocket::OpeningHandshake::Client.new(:url => url)
      send_data @hs.to_s
      @frame = LibWebSocket::Frame.new

      @channels = {}
      @globals  = {}

      bind_event 'pusher:connection_established' do |data|
        @socket_id = data['socket_id']
        @channels.each_key { |k| bind_channel k }
      end
    end

    def receive_data data
      if !@hs.done?
        raise @hs.error unless @hs.parse(data)
      else
        @frame.append data
      end

      while message = @frame.next
        json = JSON.parse(message)
        data = JSON.parse(json['data'])

        if @channels.key?(json['channel'])
          arr = @channels[json['channel']][json['event']]
          next if arr.nil?
          arr.each{ |cb| cb.call data }
        elsif @globals.key?(json['event'])
          @globals[json['event']].each{ |cb| cb.call data }
        else
          Rails.logger.debug "Ignored message: #{message}"
          # ignored event...
        end
      end
    end

    def bind_event channel, event = nil, &block
      if event.nil?
        (@globals[channel] ||= []) << block
      else
        if !@channels.key? channel
          @channels[channel] ||= {}
          bind_channel channel if @hs.done?
        end
        (@channels[channel][event] ||= []) << block
      end
    end

    def unbind
      raise 'The websocket connection has closed!'
    end

    protected

    def send_event event, data
      send_data @frame.new(JSON.dump(:event => event, :data => data)).to_s
    end

    def bind_channel channel
      data = {:channel => channel, :auth => nil, :channel_data => nil}
      if channel =~ /^private-/
        data[:auth] = Pusher.key + ':' +
          HMAC::SHA256.hexdigest(Pusher.secret, @socket_id + ':' + channel)
      end
      send_event 'pusher:subscribe', data
    end

  end
end
