class Radio
  class FargoDaemon < Radio::Daemon
    
    DEFAULTS = {:port => 37173}
    
    def run
      Fargo.logger = ::Rails.logger
      
      proxy = Radio::Proxy::FargoServer.new :client => Fargo::Client.new, :port => @port || DEFAULTS[:port]
      proxy.connect

      sleep
    end
    
    def daemon_name
      'fargo'
    end
    
  end
end
