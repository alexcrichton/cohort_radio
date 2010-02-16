class Radio
  module Proxy
    class Server
      
      include Utils
    
      attr_accessor :port
    
      def initialize options = {}
        @port = options[:port]
        @for = options[:for]
        @connections = []
      end
    
      def connect
        Rails.logger.info "Starting management server on port: #{@port}"
        @server = TCPServer.new @port
        @thread = Thread.start { loop { 
          socket = @server.accept
          @connections << Thread.start {
            data = socket.gets(DELIM) # get data 
            disconnect if data.nil?

            answer socket, decode(data)
            @connections.delete Thread.current
          }
        } }
      end
    
      def disconnect
        Rails.logger.info "Stopping management server on port: #{@port}"
        @connections.each &:exit
        @thread.exit unless @thread.nil?
        @server.close unless @server.nil?
        @server = @thread = nil
      rescue => e
        Rails.logger.error "Error disconnecting management server #{e}"
        Exceptional.handle e
      end
      
      def answer socket, data
        proxy socket, *data
      end
      
      private
      def proxy socket, *args
        # Send the method to the client, returning the result.
        # The socket is then closed.
        begin
          Rails.logger.debug "Management Server received: #{args.inspect}"
          value = @for.send *args
          Rails.logger.debug "Management Server sending: #{value.inspect}"
          socket << encode(value)
        rescue => e
          Rails.logger.error "Server ERROR: #{e}"
          socket << encode(e) unless socket.closed?
        end
        socket.close
      end
      
      
    end
  end
end