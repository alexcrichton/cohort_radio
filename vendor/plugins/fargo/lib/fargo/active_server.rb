module Fargo
  class ActiveServer
  
    def initialize(options = {})
      @options = options
      @peers = []
    end
  
    def connect
      @server ||= TCPServer.new @options[:port]
    
      @active_thread = Thread.start { loop {
        connection = Fargo::Connection::Upload.new @options
        connection.socket = @server.accept
        connection.listen
        @peers << connection
      } }
    end
  
    def disconnect
      @active_thread.exit if @active_thread
      begin
        @server.close if @server
        @server = nil
      rescue
      end
      @peers.each{ |p| p.disconnect } 
      @peers.clear
    end
  
  end
end