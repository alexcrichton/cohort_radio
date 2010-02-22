module Fargo
  module Utils
    module Publisher
      
      attr_reader :subscribers

      def subscribe &subscriber
        raise RuntimeError.new("Need a subscription block!") if subscriber.nil?
        (@subscribers ||= []) << subscriber
      end
      
      def subscribed_to?
        @subscribers && @subscribers.size > 0
      end
      
      def unsubscribe &subscriber
        raise RuntimeError.new("Need a subscription block!") if subscriber.nil?
        (@subscribers ||= []).delete subscriber
      end
  
      def publish message_type, hash = {}
        @subscribers.each { |subscriber| subscriber.call message_type, hash } if @subscribers
      end
    end
  end
end