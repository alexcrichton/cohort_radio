class Radio
  class FargoDaemon < Radio::Daemon
    
    DEFAULTS = {:port => 37173}
    
    @@enqueue_lock = Mutex.new
    
    def run
      Fargo.logger = ::Rails.logger
      
      client = Fargo::Client.new
      
      proxy = Radio::Proxy::FargoServer.new :client => client, :port => @port || DEFAULTS[:port]
      proxy.connect
      
      @converting = []
      client.subscribe { |type, hash|
        if type == :download_finished
          thread = Thread.start { 
            convert_song hash[:file] 
            @converting.delete thread
          }
          @converting << thread
        end
      }

      trap("INT")  { proxy.disconnect; client.disconnect; finish_conversions; exit }
      trap("TERM") { proxy.disconnect; client.disconnect; finish_conversions; exit }

      sleep
    end
    
    def finish_conversions
      @converting.each &:join
      @converting.clear
    end
    
    def convert_song file
      # Only enqueue one thing at a time. There was problems running into the connection
      # pool running low as a result of many downloads finishing simultaneously. A pool
      # of 10 ran out very quickly.
      @@enqueue_lock.synchronize { 
        Fargo.logger.debug "Queueing create song job for: #{file.inspect}"
        ActiveRecord::Base.verify_active_connections!
        Delayed::Job.enqueue CreateSongJob.new(file)
      }
    end
    
    def daemon_name
      'fargo'
    end
    
  end
end
