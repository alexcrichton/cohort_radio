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
          return c if c.connected?
          @connection_cache.delete nick
        end
        nil
      end
      
      def setup_connection_cache
        @connection_cache = {}
      end
      
      
    end
  end
end