class Radio
  class FargoDaemon < Radio::Daemon
    
    DEFAULTS = {:port => 37173}
    
    @@enqueue_lock = Mutex.new
    
    def run
      Fargo.logger = Rails.logger
      ActiveRecord::Base.connection.reconnect!
      
      client = Fargo::Client.new
      
      options = {:client => client}
      if @path || DEFAULTS[:path]
        options[:path] = @path || DEFAULTS[:path]
      else
        options[:port] = @port || DEFAULTS[:port]
      end
      
      proxy = Radio::Proxy::FargoServer.new options
      
      # If a download just finished, we're going to want to convert the
      # file to put it in our database. Do this in separate threads
      # to not hang things up.
      client.subscribe { |type, hash|
        if type == :download_finished
          spawn_thread { 
            convert_song hash[:file] 
            thread_complete
          } 
        end
      }
      
      trap('TERM') { Fargo.logger.info 'Exiting...'; proxy.disconnect }
      trap('INT')  { Fargo.logger.info 'Exiting...'; proxy.disconnect }

      proxy.connect

      client.disconnect
      join_all_threads
    end
        
    def convert_song file
      # Only enqueue one thing at a time. There was problems running into the connection
      # pool running low as a result of many downloads finishing simultaneously. A pool
      # of 10 ran out very quickly.
      @@enqueue_lock.synchronize { 
        Fargo.logger.info "Queueing create song job for: #{file.inspect}"
        ActiveRecord::Base.verify_active_connections!
        Delayed::Job.enqueue CreateSongJob.new(file)
      }
    end
    
    def daemon_name
      'fargo'
    end
        
  end
end
