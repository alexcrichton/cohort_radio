class Radio
  module Proxy
    class Client
      
      include Utils
      
      attr_accessor :port
    
      def initialize options = {}
        @port = options[:port]
      end
      
      def proxy_data *things
        socket = open_socket
        socket << encode(things)
        obj = decode socket.gets(DELIM)
        socket.close
        if obj.is_a?(Exception)
          Exceptional.handle obj
          raise obj
        end
        obj
      end
      
      def method_missing name, *args
        proxy_data name, *args
      end
      
      def open_socket
        TCPSocket.open '127.0.0.1', @port
      end
      
    end
    
  end
end