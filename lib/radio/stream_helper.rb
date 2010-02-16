class Radio
  module StreamHelper
    
    def radio
      @radio_management_client ||= ::Radio::Proxy::Client.new :port => ProxyDaemon::DEFAULTS[:port]
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
