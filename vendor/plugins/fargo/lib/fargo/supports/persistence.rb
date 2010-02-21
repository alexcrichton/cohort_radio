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
        @connection_cache[nick] if @connection_cache
      end
      
      def setup_connection_cache
        @connection_cache = {}
      end
      
      
    end
  end
end