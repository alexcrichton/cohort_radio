class Radio
  module FargoHelper
    
    def fargo
      return @fargo_management_client if defined?(@fargo_management_client)
      
      @fargo_management_client = ::Radio::Proxy::FargoClient.new
      
      if FargoDaemon::DEFAULTS[:path]
        @fargo_management_client.path = FargoDaemon::DEFAULTS[:path]
      else
        @fargo_management_client.port = FargoDaemon::DEFAULTS[:port]
      end
    end
  
    def fargo_running?
      !(fargo.connected? =~ /error/i)
    rescue Errno::ECONNREFUSED
      false
    end
  
    def fargo_connected?
      fargo_running? && fargo.connected?
    end
    
  end
end
