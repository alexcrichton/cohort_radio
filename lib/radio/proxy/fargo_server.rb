class Radio
  module Proxy
    class FargoServer < Server
      
      attr_accessor :client
    
      def initialize options = {}
        @client = options[:for] = options[:client]
        super
        
        @subscriptions = []
        
        # Subscribe to the client and publish everything over the server
        @client.subscribe { |type, hash|
          Fargo.logger.debug "#{self} publishing: #{type.inspect}, #{hash.inspect}"
          # encode the data as an array
          data = encode [type, hash]
          
          # Publish this data over all subscriptions
          @subscriptions.each{ |socket| 
            if socket.closed?
              @subscriptions.delete socket
            else
              begin
                socket << data
              rescue => e
                Fargo.logger.error "Error writing to subscription socket: #{type.inspect}, #{hash.inspect}"
                Exceptional.handle e
                socket.close rescue nil
                @subscriptions.delete socket
              end
            end
          }
        }
      end
    
      def new_subscription? obj
        obj == 'new_client_subscription'
      end
      
      # Override this method to correctly handle new subscriptions
      def answer socket, *args
        if new_subscription? args[0]
          @subscriptions << socket
        else
          super
        end
      end
      
    end
  end
end