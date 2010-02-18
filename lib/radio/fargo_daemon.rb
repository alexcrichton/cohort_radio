class Radio
  class FargoDaemon < Radio::Daemon
    
    DEFAULTS = {:port => 37173}
    
    def run
      Fargo.logger = ::Rails.logger
      Fargo.logger.level = 0
      
      client = Fargo::Client.new
      
      proxy = Radio::Proxy::FargoServer.new :client => client, :port => @port || DEFAULTS[:port]
      proxy.connect

      trap("INT") { proxy.disconnect; client.disconnect; exit }
      trap("TERM") { proxy.disconnect; client.disconnect; exit }      

      sleep
    end
    
    def daemon_name
      'fargo'
    end
    
  end
end
