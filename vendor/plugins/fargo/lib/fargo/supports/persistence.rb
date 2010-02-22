module Fargo
  module Supports
    module Persistence
      
      def self.included(base)
        base.after_setup :setup_connection_cache
      end
      
      def lock_connection_with! nick, connection
        @connection_cache[nick] = connection
      end
      
      def connection_for nick
        if @connection_cache
          c = @connection_cache[nick]
          return c if c.nil? || c.connected?
          @connection_cache.delete nick
        end
        nil
      end
      
      def connected_with? nick
        if @connection_cache
          c = @connection_cache[nick]
          return c.connected? unless c.nil?
        end
        false
      end 
      
      def nicks_connected_with
        return [] if @connection_cache.nil?
        nicks = @connection_cache.keys
        nicks.reject{ |n| !connected_with? n } 
      end
      
      def setup_connection_cache
        @connection_cache = {}
      end
      
    end
  end
end