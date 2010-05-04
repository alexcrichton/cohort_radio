module Fargo
  module ProxyHelper
    
    def fargo
      return @fargo_management_client if defined?(@fargo_management_client)
      
      @fargo_management_client = ::Fargo::Proxy::Client.new
      
      if Fargo.config[:proxy][:path]
        @fargo_management_client.path = Fargo.config[:proxy][:path]
      else
        @fargo_management_client.port = Fargo.config[:proxy][:port]
      end
      
      @fargo_management_client
    end
  
    def fargo_running?
      !(fargo.connected? =~ /error/i)
    rescue Errno::ECONNREFUSED, Errno::ENOENT
      false
    end
  
    def fargo_connected?
      fargo_running? && fargo.connected?
    end
    
  end
end
