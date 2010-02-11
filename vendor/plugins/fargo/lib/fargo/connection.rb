module Fargo
  
  class ConnectionError < RuntimeError; end

  class Connection
  
    include Fargo::Utils::Publisher
  
    attr_accessor :options, :socket
      
    def initialize(opts = {})
      @outgoing = Queue.new
      @options = opts
    end
  
    def [](key)
      options[key]
    end
  
    def []=(key, value)
      options[key] = value
    end
  
    def connect
      raise Fargo::ConnectionError.new("There's no receive method!") unless respond_to? :receive
      pre_connect if respond_to? :pre_connect
      open_socket  
      listen
      post_connect if respond_to? :post_connect
    end
  
    def open_socket
      @socket ||= TCPSocket.open self[:address], self[:port]
    rescue Errno::ECONNREFUSED
      raise Fargo::ConnectionError.new "Couldn't open a connection to #{self[:address]}:#{self[:port]}"
    end
    
    def connected?
      !@socket.nil?
    end
    
    def read_data
      data = @socket.gets "|"
      if data.nil?
        publish :socket_gone
        disconnect
      else
        puts "#{self} Received: #{data.inspect}" if defined?(Fargo::DEBUG)
        receive data.chomp('|')
      end
    rescue IOError
      disconnect
    end
    
    def write_data
      data = @outgoing.pop
      puts "#{self} Sending: #{data.inspect}" if defined?(Fargo::DEBUG)
      @socket << data
    rescue 
      publish :write_error
      disconnect
    end

    def listen
      return unless @threads.nil? || @threads.size > 0
      @threads = []
      # Start a thread to read the socket
      @threads << Thread.start { loop { read_data } }
      # Start a thread to send information from the queue
      @threads << Thread.start { loop { write_data } }
      post_listen if respond_to? :post_listen
    end
  
    def disconnect
      write "$Quit #{self[:nick]}"
      @threads.each { |thread| thread.exit } if @threads
      if @socket
        begin
          @socket.close
          @socket = nil
        rescue
        end
      end
      @outgoing.clear

      publish :disconnected
    end
  
    def write(string)
      string << '|' unless string =~ /\|$/
      @outgoing << string
    end
  
  end
end