require 'socket'
require 'util'

#base class for Connections to clients and hubs
class DCConnection
  attr_reader :hostname, :port
  attr	:socket
  
  include Publisher
  
  def initialize
    @messages = Queue.new
    @outgoing = Queue.new
  end
  
  def connect
    @hostname = hostname
    @port = port
    # Do this in the background, or we'll stall up the GUI and stuff.
    #actually it'll stall anyway :( something to do with ruby threads and technical things
    backgroundedly do
      info "Connecting to %s:%d...\n", @hostname, @port
      @socket = TCPSocket.new @hostname, @port
      info "Connected to %s:%d.\n", @hostname, @port
      post_connect
      run
    end
  end
  
  def run
   # puts "#{@hostname} calling run"
    @threads = [start_reader_thread,
                start_writer_thread,
                start_action_thread]
   # puts "reader thread #{@threads[0]}"
  end
  
  #kill the connection, kill it's associated threads, etc
  def quit
    @threads.each { |thread| thread.terminate } if @threads
    if @socket
      begin
        @socket.shutdown
        @socket=nil
      rescue
        puts "socket already disconnected"
      end
    end
    @messages.clear
    @outgoing.clear
  end

  def join
    @threads.each { |thread| thread.join }
  end

  def post_connect
  end
  
  def read_message
    data = @socket.gets "|"
    if data != nil then
      parsed = parse_message(data.chomp("|"))
      @messages << parsed
    else
      publish :disconnected
      quit
    end
  end
  
  def start_reader_thread
    concurrent_loop { read_message }
  end
  
  def start_writer_thread
    concurrent_loop do
      begin
        data = @outgoing.pop
        puts "sending #{data}"
        @socket << data
      rescue 
        puts $!
        publish :write_error
        quit
      end
    end
  end
  
  def start_action_thread
    concurrent_loop { handle_message @messages.pop }
  end
  
  def write(string)
    @outgoing << string
  end
  
  def reply(format, *args)
    message = (sprintf format, *args) + "|"
    write message
  end
end

