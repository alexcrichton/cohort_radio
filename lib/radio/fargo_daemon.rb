class Radio
  class FargoDaemon < Radio::Daemon
    
    DEFAULTS = {:port => 37173}
    
    def run
      Fargo.logger = ::Rails.logger
      
      client = Fargo::Client.new
      
      proxy = Radio::Proxy::FargoServer.new :client => client, :port => @port || DEFAULTS[:port]
      proxy.connect
      
      @enqueue_lock = Mutex.new
      
      client.subscribe { |type, hash|
        if type == :download_finished
          # Only enqueue one thing at a time. There was problems running into the connection
          # pool running low as a result of many downloads finishing simultaneously. A pool
          # of 10 ran out very quickly.
          @enqueue_lock.synchronize{ 
            failed = true
            while failed
              # Even though we're synchronized, the error still happened, so let's just retry the
              # file until it doesn't fail by catching the exception.
              begin
                Delayed::Job.enqueue CreateSongJob.new(hash[:file]) 
                failed = false
              rescue ActiveRecord::ConnectionTimeoutError 
                Fargo.logger.error "Database timeout error!"
                Fargo.logger.error "Retrying file: #{hash[:file]}"
              end
            end
          }
        end
      }

      trap("INT")  { proxy.disconnect; client.disconnect; exit }
      trap("TERM") { proxy.disconnect; client.disconnect; exit }      

      sleep
    end
    
    def daemon_name
      'fargo'
    end
    
  end
end
