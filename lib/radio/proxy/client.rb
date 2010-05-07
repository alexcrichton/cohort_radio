class Radio
  module Proxy
    class Client
      
      include Utils
      
      attr_accessor :port, :path
    
      def initialize options = {}
        @port = options[:port]
        @path = options[:path]
      end
      
      def proxy_data *things
        socket = open_socket
        
        socket << encode(things)          # write our data
        obj = decode socket.gets(DELIM)   # get the response
        socket.close
        
        # handle exceptions appropriately
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
        if @port
          TCPSocket.open '127.0.0.1', @port
        else
          UNIXSocket.open @path
        end
      end
      
    end
    
  end
end