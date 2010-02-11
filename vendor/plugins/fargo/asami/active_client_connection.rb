#this is called ActiveClientConnection but it's for all client to client connections
require 'client_parser.rb'


class ActiveClientConnection < DCConnection
  attr_reader :config, :remote_nick,:wanted_file,:full_path, :downloaded, :file_length, :downloading
  attr_accessor :hub, :direction, :rate, :time, :chunksize
  def method_missing(name, *args)
    puts "#{@hostname} tried to call #{name} with #{args}"
  end
  #creates a new connection, with the ui and if possible, the config for the hub it come from
  def initialize(ui,config)
    super()
    @config = config
    @offset=0
    @rate=0
    @downloading = false
    @buffer_size = 2**12
    @buffer = ""
    @hostname=""
    @time=nil
    @ui=ui
    @direction=:download
    @socket=nil
    @time=0
    @hub=nil
    @inactive=false
    @haveslot=false
    @sentlock=false
    @timer=nil
    @supports={}
    @direction=:upload
    @blockend=0
    @chunksize=0
  end
  
  #start it going
  def listen
    run
  end
  
  #pass it a socket that the main listening socket creates
  def setsocket(what)
    @socket=what
  end
  
  #some post-connect setup
  def post_connect
    @hub = @ui.hub_by_user_ip @socket.peeraddr[3]
    if @direction==:upload
      reply "$MyNick %s", @hub.get('nick')
      reply "$Lock %s Pk=%s", ("EXTENDEDPROTOCOL"+"abcd" * 6), ("df23" * 4)
      @sentlock=true
    end
  end
  
  #close it all down, stop the progress timer
  def quit
    #puts "#{@hostname} quitting"
    #puts "reader thread #{@threads[0]}"
    super
    @threads[0].kill
  #  Gtk::timeout_remove(@timer) if @timer
  end
	
  #process a raw message from the other client
  def parse_message(text)
    ClientParser.parse_message text
  end
  
  #read messages/data
  def read_message
    return if @socket.closed?
    if @downloading == false
      data = @socket.gets "|"
      if data != nil then
        parsed = parse_message(data.chomp("|"))
        @messages << parsed
      else
       # puts "this thing"
        publish(:disconnected,{:file=>@wanted_file||"",:direction=>@direction,:hub=>@hub})
        quit
      end
    else
      download_chunk
      sleep 1.0/(@rate/2.0) unless @rate==0
    end
  end
  
  #process a piece of data, stick it to the file, etc
  def download_chunk
    if @file_length == @downloaded
      @downloading = false
      @output.close
      Gtk::timeout_remove(@timer) if @timer
      publish(:done_downloading, {:file => @wanted_file,
                                  :from => @remote_nick,
                                  :hub => @hub,
                                  :fsize => @downloaded})
      if @ui.wanted_file? @remote_nick
        @wanted_file = @ui.wanted_file?
        begin
          @offset = File.size(File.basename(@hub.get('downloadtarget') +'/' +@wanted_file)) if @wanted_file!="MyList.DcLst"
        rescue
          @offset=0
        end
        @wanted_file=@wanted_file.gsub("/", "\\")
        reply("$Get %s$%d", @wanted_file,@offset+1)
      end
      @inactive=true
    else
      if (@file_length - @downloaded) < @buffer_size
        data = @socket.sysread(@file_length - @downloaded)
      else
        data = @socket.sysread(@buffer_size)
      end
      if data
        @output << data
        @downloaded += data.length
        @chunksize+=data.length
      else
        #@downloading = false
        @output.close
        quit
        Gtk::timeout_remove(@timer) if @timer
        publish(:premature_end_of_download, {:file => @wanted_file,
                                             :from => @remote_nick})
      end
    end
  end
  
  #connect to a specified hostname, port
  def connect (hostname,port)
    @hostname = hostname
    @port = port
    @direction=:upload
    super()
  end
  
  
  #handle a parsed message object
  def handle_message(message)
    @inactive=false
    #puts message
    case message[:type]
      
    when :mynick
      @remote_nick=message[:nick]
      @hub = @ui.find_user(message[:nick])[0] unless @hub
      @ui.connections[@remote_nick]=self
      @wanted_file,@dir = @ui.wanted_file?(message[:nick])
      if @wanted_file
        @direction=:download 
        @rate=@hub.get('downloadrate')||0
        begin
          @offset = File.size(@hub.get('downloadtarget') +'/'+File.basename(@wanted_file.gsub("\\","/"))) if @wanted_file!="MyList.DcLst"
          @offset-=2048
          @offset=0 if @offset < 0
        rescue
          @offset=0
        end
        @wanted_file = @wanted_file.gsub("/", "\\")
      else
        @direction=:upload
        @wanted_file=""
        @rate=@hub.get('uploadrate')||0
      end
      publish(:nick,{:nick=>@remote_nick,:file=>@wanted_file||""})
      
    when :lock
      @key = message[:key]
      if message[:lock]=~/^EXTENDEDPROTOCOL/
        reply "$Supports MiniSlots BZList XmlBZList"
      end
      if @direction == :download
        reply "$MyNick %s", @hub.get('nick')
        reply "$Lock %s Pk=%s", ("EXTENDEDPROTOCOL"+"abcd" * 12), ("dfd1" * 4)
        reply("$Direction Download %d", rand(100000))
        reply "$Key %s", @key
      else 
        unless @sentlock
          reply "$MyNick %s", @hub.get('nick')
          reply "$Lock %s Pk=%s", ("EXTENDEDPROTOCOL"+"abcd" * 12), ("dfd1" * 4)
          reply("$Direction Upload %d", rand(100000))
          reply "$Key %s", @key
        else
          reply "$Key %s", @key
        end
      end
      
    when :key
      if @direction==:download
        if @wanted_file=="#{@remote_nick}.DcLst"||@wanted_file=="#{@remote_nick}.bz2"
          reply("$Get MyList.DcLst$%d",@offset+1)
        elsif @wanted_file=="#{@remote_nick}.bz2"
            reply("$Get MyList.bz2$%d",@offset+1)
        elsif @wanted_file=="#{@remote_nick}.xml.bz2"
          reply("$Get files.xml.bz2$%d",@offset+1)
        else
          reply("$Get %s$%d", @ui.full_path?(@wanted_file,@remote_nick),@offset+1)
        end
      else
        reply "$Direction Upload 21312"
        reply "$Key %s",@key	  
      end
      
    when :direction
      puts "direction called #{message}"
      @direction=:download if message[:direction]==:upload
      publish(:direction,{:direction => message[:direction]})
      
    when :noslots
      publish(:noslots,{:nick => @remote_nick})
      
    when :get
      @offset=message[:offset]
      start_uploading message[:path]
      
    when :ugetblock
      puts "start #{message[:start]} finish #{message[:finish]}"
      @offset=message[:start]
      @blockend=message[:finish]
      start_uploading message[:path]
      
    when :send
      publish :send_request
      start_uploader
      
    when :write_error
      kill_uploader
      quit
      
    when :file_length
      @downloading = true
      @file_length = message[:length]
      @downloaded = @offset
    
      @socket.sync = true
      if @wanted_file=="#{@remote_nick}.DcLst"||@wanted_file=="#{@remote_nick}.bz2"||@wanted_file=="#{@remote_nick}.xml.bz2"
        @output = File.new(File.join(File.expand_path("~/.Asami/Filelists/"),@wanted_file),File::WRONLY|File::CREAT)
      else
        @output = File.new(@hub.get('downloadtarget')+'/'+File.basename(@wanted_file.gsub(/\\/, '/')), File::WRONLY|File::CREAT)
      end
      @output.seek @offset
      @output.sync=true
      publish(:downloadstart, {:file => @wanted_file,:size=>@file_length})
      reply "$Send"
      
      
    when :disconnected
      @ui.release_slot if @haveslot
      @haveslot=false
      publish(:disconnected,{:file=>@wanted_file||"OH",:direction=>@direction,:hub=>@hub})
      quit
      Gtk::timeout_remove(@timer) if @timer
      
    when :supports
      @supports[:bzlist] = message[:extensions].include? "BZList"
      @supports[:minislot] = message[:extensions].include? "MiniSlots"
      @supports[:xmlbzlist]=message[:extensions].include? "XmlBZList"
      #warning "%s supports %s",@remote_nick,message[:extensions]
      @wanted_file=@wanted_file.gsub("DcLst","xml.bz2") if(@supports[:xmlbzlist] && @wanted_file=~/DcLst/)
      @wanted_file=@wanted_file.gsub("DcLst","bz2") if(@supports[:bzlist] && @wanted_file=~/DcLst/)
      publish(:supports,{:bzlists=>@supports[:bzlist],:xmlbzlists=>@supports[:xmlbzlist]})

    when :error
      if message[:message]=="File Not Available"
        publish(:notavailable,{:file=>@wanted_file})
      else
        warning "Error %s\n",message[:message]
      end
    else
      warning "%s sent `%s'.  Um?\n", @remote_nick, message.inspect
    end
  end
  
  #stop the transaction
  def cancel
    reply "$Cancel"
  end
	
  #set up the uploading stuff
  def start_uploading(path)
    if path=="files.xml.bz2"
      @full_path=File.expand_path("~/.Asami/mylists/#{@hub.favname}.xml.bz2")
    elsif path =~/MyList.(DcLst|bz2)/
      @full_path = File.expand_path("~/.Asami/mylists/#{@hub.favname+"."+$1}")
    else
      path=path.gsub(/\\/,"/")
      if path=~/(.*?)\/(.*)/
        @full_path = File.join(@hub.foldermap[$1],$2)
      else
        @full_path=path
      end
    end
    
    begin
      @file_length = File.size(@full_path)
    rescue
      puts $!
      reply "$Error File Not Available"
      return
    end
    if (@file_length < 1024 || path == "MyList.DcLst" || path == "MyList.bz2"||@ui.get_slot )
      publish(:get, {:path => path,
                     :offset => @offset})
      reply("$FileLength %d", @file_length)
      @haveslot=true
    else
      reply "$MaxedOut"
    end
  end

  #start the actual uploader thread
  def start_uploader
    @downloading=true
    @uploader = Thread.start do
      begin
        file = File.new @full_path, "r"
        file.seek @offset, IO::SEEK_SET
        @downloaded = @offset
        #@time=Time.new
        file.each_n_bytes(2**11) do |buffer|
          begin
            @socket.write(buffer) if buffer
            @chunksize += buffer.length
            @downloaded+=buffer.length
            break if @downloaded > @blockend && @blockend !=0
          rescue
            warning "problem\n"
            warning "#{$!}\n"
            reply "$Cancel"
            quit
            break
          end
          sleep 1.0/(@rate/2.0) unless @rate==0
        end
        file.close
        @inactive=true
        Gtk::timeout_add(30000)do
          if @inactive 
            quit
          end
          false
        end
        if @haveslot
          @ui.release_slot
          @haveslot=false
        end
        publish(:upload_complete, {:path => @full_path,
                                   :size => @file_length,:offset => @offset,
                                   :to => @remote_nick,:hub => @hub}
                )
      rescue
        warning "something went wrong sending, but who cares\n"
        warning "#{$!}"
      end
      puts "uploader thread ending"
      @downloading=false
    end
    
  end
  
  #print things we are saying to the other client in red
 # def reply(format, *args)
  #  warning(sprintf(format, *args))
   # super
  #end
  
  #kill the uploader thread
  def kill_uploader
    @uploader.kill if @uploader
  end

  #has this got a slot
  def has_slot?
    @haveslot
  end

  #set its slotted status
  def has_slot=(lol)
    @haveslot=lol
  end

  def hub_quitting(quittinghub)
    warning "Quitting hub\n"
    if quittinghub==@hub && @hub.get('disconnect')
      warning "Cancelling"
      reply "$Cancel"
      quit
    end
  end

end
