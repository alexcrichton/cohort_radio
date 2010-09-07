require 'drb'

class Radio
  module ProxyHelper
    
    def radio
      @radio_client ||= DRbObject.new_with_uri('drbunix:///tmp/radio.sock')
    end
  
    def radio_running?
      !(radio.connected? =~ /error/i)
    rescue DRb::DRbConnError, Errno::ENOENT
      false
    end
  
    def radio_connected?
      radio_running? && radio.connected?
    end
    
  end
end
