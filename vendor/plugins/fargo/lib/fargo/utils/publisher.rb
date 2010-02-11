module Fargo
  module Utils
    module Publisher

      def subscribe(&subscriber)
        (@subscribers ||= []) << subscriber
      end
      
      def unsubscribe &subscriber
        (@subscribers ||= []).delete subscriber
      end
  
      def publish(*args)
        @subscribers.each { |subscriber| subscriber.call *args } if @subscribers
      end
    end
  end
end