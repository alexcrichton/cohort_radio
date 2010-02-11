module Fargo
  module Management
    class Server
      
      include Utils
    
      attr_accessor :port, :client
    
      def initialize(options = {})
        @port = options[:port]
        @client = options[:client]
        @connections = []
      end
    
      def connect
        # @client.connect unless @client.connected?
        @server = TCPServer.new @port
        @thread = Thread.start {
          loop {
            socket = @server.accept
            thread = Thread.start {
              args = decode socket.gets("\005")
              puts "Server: #{args.inspect}" if defined?(Fargo::DEBUG)
              begin
                value = @client.send(*args)
                puts "Server: #{value.inspect}" if defined?(Fargo::DEBUG)
                socket << encode(value)
              rescue Exception => e
                puts 'Server ERROR:', e if defined?(Fargo::DEBUG)
                socket << encode("error\005")
              end
              socket.close
              @connections.delete thread
            }
            @connections << thread
          }
        }
      end
    
      def disconnect
        @connections.each &:exit
        @thread.exit
        @server.close
      rescue IOError
      end
    end
  end
end