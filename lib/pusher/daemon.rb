require 'em-websocket'
require 'active_support/message_verifier'
require 'drb'
require 'radio'
require File.expand_path('../../../config/initializers/secret_token', __FILE__)

module Pusher
  module Daemon

    def self.run
      Radio.setup_logging 'pusher.log'

      @key      = Rails.application.config.secret_token
      @channel  = EventMachine::Channel.new
      @verifier = ActiveSupport::MessageVerifier.new @key

      DRb.start_service 'druby://127.0.0.1:8081', @channel

      EventMachine.epoll

      EventMachine.error_handler{ |e|
        puts "Error raised during event loop: #{e.message}"
        puts e.backtrace.join("\n")
      }

      EventMachine.run {
        EventMachine::start_server('0.0.0.0', 8080,
            EventMachine::WebSocket::Connection, {}) do |ws|
          ws.onopen {
            cookies = Rack::Utils.parse_query ws.request['Cookie']

            begin
              session = @verifier.verify cookies['_cradio_session']
            rescue ActiveSupport::MessageVerifier::InvalidSignature
              session = {}
            end

            user_id = session['warden.user.user.key'] # of the form [klass_str, id]

            if user_id
              sid = @channel.subscribe do |data|
                ws.send data[:data] unless data[:except].include?(user_id[1])
              end

              ws.onclose { @channel.unsubscribe sid }
            else
              ws.unbind
            end
          }
        end

        puts "Server started"
      }
    end

  end
end
