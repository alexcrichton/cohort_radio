class Radio
  module FargoHelper
    def fargo
      @fargo_management_client ||= ::Radio::Proxy::FargoClient.new :port => FargoDaemon::DEFAULTS[:port]
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
