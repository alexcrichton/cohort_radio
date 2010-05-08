class Radio
  module Proxy
    module Utils
      
      DELIM = "\005"
      
      def encode arg
        data = Base64.encode64 Marshal.dump(arg)
        data << DELIM
        data
      end
      
      def decode data
        return nil if data.nil?
        data = data.chomp DELIM
        Marshal.load Base64.decode64(data)
      rescue TypeError
        nil
      end
            
      def spawn_thread &block
        @spawned_threads ||= []
        
        @spawned_threads << Thread.start{ instance_eval(&block) }
      end
      
      def thread_complete
        (@spawned_threads ||= []).delete Thread.current
      end
      
      def join_all_threads
        @spawned_threads ||= []
        @spawned_threads.each &:join
        @spawned_threads.clear
      end
      
    end
  end
end
