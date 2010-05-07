class Radio
  class ProxyDaemon < Radio::Daemon
        
    def daemon_name
      'radio'
    end
    
    def run
      Rails.logger = Logger.new $stdout
      ActiveRecord::Base.connection.reconnect!
      
      radio = Radio.new
      
      options = {:for => radio}
      if @path || Radio.config[:proxy][:path]
        options[:path] = @path || Radio.config[:proxy][:path]
      else
        options[:port] = @port || Radio.config[:proxy][:port]
      end
      
      @proxy = Radio::Proxy::Server.new options
      
      trap("INT")  { Rails.logger.info 'exiting...'; @proxy.disconnect }
      trap("TERM") { Rails.logger.info 'exiting...'; @proxy.disconnect }
      
      Rails.logger.info "Connecting radio..."
      
      @proxy.connect
      
      radio.disconnect
    end
    
  end
end
