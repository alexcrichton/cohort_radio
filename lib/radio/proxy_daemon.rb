class Radio
  class ProxyDaemon < Radio::Daemon
    
    DEFAULTS = {:port => 31743}
    
    def daemon_name
      'radio'
    end
    
    def run
      ActiveRecord::Base.connection.reconnect!
      
      radio = Radio.new
      
      @thread = Thread.current
      
      proxy = Radio::Proxy::Server.new :for => radio, :port => @port || DEFAULTS[:port]
      proxy.connect

      trap("INT")  { Rails.logger.info 'exiting...'; $exit = true }
      trap("TERM") { Rails.logger.info 'exiting...'; $exit = true }
      
      while !$exit
        sleep 5
      end
      
      proxy.disconnect
      radio.disconnect
      
    end
    
  end
end
