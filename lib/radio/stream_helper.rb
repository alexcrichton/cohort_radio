class Radio
  module StreamHelper
    
    def radio
      return @radio_management_client if defined?(@radio_management_client)
      
      @radio_management_client = ::Radio::Proxy::Client.new
      
      if Radio.config[:proxy][:path]
        @radio_management_client.path = Radio.config[:proxy][:path]
      else
        @radio_management_client.port = Radio.config[:proxy][:port]
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
