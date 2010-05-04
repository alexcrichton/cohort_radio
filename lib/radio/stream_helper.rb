class Radio
  module StreamHelper
    
    def radio
      return @radio_management_client if defined?(@radio_management_client)
      
      @radio_management_client = ::Radio::Proxy::Client.new
      
      if ProxyDaemon::DEFAULTS[:path]
        @radio_management_client.path = ProxyDaemon::DEFAULTS[:path]
      else
        @radio_management_client.port = ProxyDaemon::DEFAULTS[:port]
      end
      
      @radio_management_client
    end
  
    def radio_running?
      !(radio.connected? =~ /error/i)
    rescue Errno::ECONNREFUSED
      false
    end
  
    def radio_connected?
      radio_running? && radio.connected?
    end
    
  end
end
