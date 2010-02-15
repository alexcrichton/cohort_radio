class Radio
  class ProxyDaemon < Radio::Daemon
    
    DEFAULTS = {:port => 31743}
    
    def daemon_name
      'radio'
    end
    
    def run
      radio = Radio.new
      Playlist.scoped.each { |p| radio.add_playlist p }
      
      proxy = Radio::Proxy::Server.new :for => radio, :port => @port || DEFAULTS[:port]
      proxy.connect

      sleep
      
    end
    
  end
end
