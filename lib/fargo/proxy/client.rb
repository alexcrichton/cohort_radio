module Fargo
  module Proxy
    class Client < Radio::Proxy::Client
      
      include Fargo::Utils::Publisher
          
      def subscribe *args, &block
        super
        open_subscription unless subscribed_to_server?
      end

      def unsubscribe *args, &block
        super
        close_subscription if subscribed_to_server?
      end
            
      def subscribed_to_server?
        !@subscription_socket.nil?
      end
      
      def open_subscription
        @subscription_socket = open_socket
        @subscription_socket << encode('new_client_subscription')
        @subscription_thread = Thread.start { loop { read_subscription } }
      end
      
      def read_subscription
        if @subscription_socket.closed?
          Fargo.logger.warn "Managment client tried to read after it's subscription was closed..."
          return close_subscription
        end
        data = @subscription_socket.gets DELIM
        args = decode data
        Fargo.logger.debug "Client subscription received: #{args.inspect}"
        publish *args
      rescue => e
        Fargo.logger.error "Error: client's subscription terminated #{e}"
        Exceptional.handle e
        close_subscription
      end
      
      def close_subscription
        @subscription_thread.exit  unless @subscription_thread.nil?
        @subscription_socket.close unless @subscription_socket.nil? || @subscription_socket.closed?
        @subscription_socket = @subscription_thread = nil
      end
    
    end
  end
end