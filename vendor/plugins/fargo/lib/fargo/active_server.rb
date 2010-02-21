module Fargo
  class ActiveServer
    
    include Fargo::Utils::Publisher
  
    def initialize(options = {})
      @options = options
      @peers = []
    end
    
    def connected?
      !@server.nil?
    end
  
    def connect
      return if connected?
      @server = TCPServer.new '0.0.0.0', @options[:port]
    
      @active_thread = Thread.start { loop {
        
        connection = Fargo::Connection::Download.new @options.merge(:first => false)
        connection.subscribe{ |type, hash| 
          publish type, hash 
          @peers.delete connection if type == :download_disconnected
        }
        connection.socket = @server.accept
        connection.listen
        @peers << connection
      } }
    end
  
    def disconnect
      puts 'disconnecting'
      @active_thread.exit if @active_thread
      begin
        @server.close if @server
      rescue
      end
      @server = nil
      @peers.each{ |p| p.disconnect } 
      @peers.clear
    end
  
  end
end