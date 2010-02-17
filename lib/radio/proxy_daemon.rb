class Radio
  class ProxyDaemon < Radio::Daemon
    
    DEFAULTS = {:port => 31743}
    
    def daemon_name
      'radio'
    end
    
    def run
      radio = Radio.new
      
      @thread = Thread.current
      
      proxy = Radio::Proxy::Server.new :for => radio, :port => @port || DEFAULTS[:port]
      proxy.connect

      trap("INT") { proxy.disconnect; radio.disconnect; exit }
      trap("TERM") { proxy.disconnect; radio.disconnect; exit }
      
      sleep
      
    end
    
  end
end
