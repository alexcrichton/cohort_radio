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
          @enqueue_lock.synchronize{ Delayed::Job.enqueue CreateSongJob.new(hash[:file]) }
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
