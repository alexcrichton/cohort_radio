#class that listens for search results
class SearchReceiver
  attr_reader :port, :address
  attr_accessor  :target,:results
  include Publisher
  @@sr=Regexp.new('^\$SR (.*?) (.*?)\005(.*?) (.*?)\/(.*?)\005(.*?) (.*?)$')
  #create a new receiver listening on specified port
  def initialize(port)
    backgroundedly do
      @target=nil
      @socket = UDPSocket.new
      @thread=nil
      @count=0
      @results=[]
      port=port.to_i
      begin
        @socket.bind "0.0.0.0", port unless port==-1
      rescue
        #port=port+1
        puts "Problem initialising the Search Response UDP socket"
        puts $!
        puts "Search will not function correctly"
      end
      unless port==-1
        @address = @socket.addr[3]
        @port = @socket.addr[1]
      end
      #puts "Listening on #{address}:#{port}"
    end
  end
  #stop the listener thread
  def stop
    Thread.kill @thread
  end
  #start a few threads going, one that listens for new results, one that processes results
  def run
    @resultsemptier=concurrent_loop do
      unless @results.empty?
        data=@results.pop
        if @@sr.match data
          @target.addinfo($1,$2,$3,$4,$5,$6) 
        end
      end
      sleep 0.05
    end
    unless port==-1
      @thread= concurrent_loop do
        data = @socket.recvfrom(512)[0]
        #puts "HEHE: #{data}"
        unless data==nil
          @results << data
        else
          #puts "Useless shit #{data} ignoring"
        end
      end
    end
  end
end
