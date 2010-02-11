module Fargo
  module Management
    class Client
      
      include Utils
      
      attr_accessor :port
    
      def initialize(options = {})
        @port = options[:port]
      end
      
      def send *things
        socket = TCPSocket.open '127.0.0.1', @port
        socket << encode(things)
        decode socket.gets("\005")
      rescue Errno::ECONNREFUSED
        "error"
      end
    
    end
  end
end