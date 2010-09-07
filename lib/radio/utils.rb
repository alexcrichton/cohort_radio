class Radio
  module Utils
                
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
