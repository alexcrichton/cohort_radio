module Fargo
  module Handler
    module Chat
      
      def self.included(base)
        base.after_setup :subscribe_to_chats
      end
      
      def messages
        @public_chats
      end
      
      def messages_with nick
        @chats[nick] if @chats
      end
      
      def subscribe_to_chats
        @public_chats = []
        @chats = Hash.new{ |h, k| h[k] = [] }

        hub.subscribe do |map|
          if map.is_a?(Hash) && (map[:type] == :privmsg || map[:type] == :chat)
            if map[:type] == :chat
              @public_chats << map
            else
              @chats[map[:from]] << map
            end
          end
        end
      end
    end
  end
end