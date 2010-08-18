class Radio
  module Proxy
    class Server
      
      include Utils
    
      attr_accessor :port
    
      def initialize options = {}
        @port = options[:port]
        @for  = options[:for]
        @path = options[:path]

        @looping = true
      end
    
      def connect
        if @path
          @server = open_unix_server
          
          at_exit { File.delete @path if @path && File.exists?(@path) }
        else
          @server = open_tcp_server
        end

        while @looping do
          socket = @server.accept
          next if socket.nil?
          
          spawn_thread {
            data = socket.gets(DELIM) # get data 
            
            # answer the request
            answer socket, decode(data) unless data.nil?
            
            thread_complete
          }
        end
      end
    
      def disconnect
        Rails.logger.info "Stopping management server on port: #{@port}"
        
        @looping = false
        @server.close unless @server.nil?
        File.delete @path if @path
        @server = nil
        
        join_all_threads
      rescue => e
        Rails.logger.error "Error disconnecting management server #{e}"
        Exceptional.handle e
      end
      
      # This is here so subclasses may overwrite this
      def answer socket, data
        proxy socket, *data
      end
      
      private
      def proxy socket, *args
        # Send the method to the client, returning the result.
        # The socket is then closed.
        begin
          Rails.logger.debug "Management Server received: #{args.inspect}"
          value = @for.send *args
          Rails.logger.debug "Management Server sending: #{value.inspect}"
          socket << encode(value)
        rescue => e
          Rails.logger.error "Server ERROR: #{e}"
          Rails.logger.error "#{e.backtrace.join("\n")}"
          socket << encode(e) unless socket.closed?
        end
        socket.close unless socket.closed?
      end
      
      def open_unix_server
        Rails.logger.info "Starting management server socket: #{@path}"
        UNIXServer.new @path
      end
      
      def open_tcp_server
        Rails.logger.info "Starting management server on port: #{@port}"
        TCPServer.new @port
      end
      
    end
  end
end