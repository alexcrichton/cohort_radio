require 'downloadqueue'
require 'search_receiver'
require 'hub_connection'

class UI

  attr_reader :active,:address,:extport,:sharesize,:upslots,:queue,:foldermap,:receiver,:config,:usershub
  attr_accessor :connections
  
  def initialize(config)
    @hubs = {}
    @peers = []
    @current = nil
    @config = config||{}
    @receiver=nil
    @wantedfiles={}
    @usershub={}
    @passives={}
    @iptohub={}
    @connections={}
    @mainsocket=nil
    @address=0
    @upslots=(@config['uploadslots']||0).to_i
    @slotlock=Mutex.new
    @searchlist=[]
    @foldermap={}
    @queue=DownloadQueue.new @config['downloadslots']||5,self,@config['queue']
    backgroundedly do 
      @config['sharedfolders'].each{|folder| @foldermap[File.basename(folder)]=folder}
      #@foldermap.each_value{|folder|@searchlist.concat(make_search_list(folder))}
      #@foldermap.each_key{|key| puts key}
    end if @config['sharedfolders']
    if @config['useextip']&&@config['extport']&&@config['active']
      @mainsocket=TCPServer.new config['extport']
      @address = config['extip']
      @receiver=SearchReceiver.new config['extport']
    else
      if @config['active']
        @mainsocket=TCPServer.new 0
        @address=@mainsocket.addr[1]
        @receiver=SearchReceiver.new @mainsocket.addr[1]
      else
        @receiver=SearchReceiver.new -1
      end
    end
      @receiver.subscribe { |type, info| handle_search_event info }
      @receiver.run
    if @config['active']
      @port = @mainsocket.addr[1]
      @listenerthread=startlistener
    end
  end

  def startlistener
    listenerthread= backgroundedly do
      loop do
        peer = ActiveClientConnection.new self, @config
        peersocket=@mainsocket.accept
        peer.setsocket peersocket
        peer.subscribe { |type,*args| handle_peer_event peer,type,*args}
        peer.listen
        @peers << peer
      end
    end
    listenerthread
  end

  def get_slot
    gotslot=false
    puts @upslots
    @slotlock.synchronize do
      if @upslots > 0
        gotslot=true
        @upslots-=1
      end
    end
    puts gotslot
    gotslot
  end

  def release_slot
    @upslots+=1
    @upslots=@config['uploadslots'] if @upslots > @config['uploadslots']
  end

  def connect(host, port)
    config = @config
    config['address'] = host
    config['port'] = port
    connect_with_config "oh",config
  end

  def connect_to_favorite(name)
    config = @config['hubs'][name]
    connect_with_config config
  end
  
  def stoplistener
    puts "OVERRIDE THIS TO STOP THE LISTENER WHEN SWITCIHNG TO PAASVEVE"
    puts "MAYBE?"
  end

  def favorites
    favs = @config['hubs'].keys
    #favs.delete 'default'
    favs
  end

  def connect_with_config(name,config)
    hc = HubConnection.new config, @config,name,self
    @hubs[config['address']] = hc
    @current = hc
    hc.subscribe { |type, *args| handle_hub_event hc, type, *args }
    hc.connect
    hc
  end

  def download_file(nick, file,hub,dir)
    puts hub
    hub=find_user(nick) unless hub
    file="#{nick}.DcLst" if file=="MyList.DcLst"
    puts "#{file} #{nick} #{hub}"
    @queue.addtoqueue(file,nick,hub.hostname,dir)
    @usershub[nick]=hub
    info "Added %s as a source for %s to the queue", nick, file
    hub.connect_to_me(nick, @address,@extport) if @queue.busy[nick]==:idle
  end

  def find_user(nick)
    #return @usershub[nick] if @usershub[nick]
    hubs=[]
    @hubs.each_value{|hub| hubs << hub if hub.has_user?(nick)}
    return hubs
  end

  def hub_by_user_ip(ip)
    return @iptohub[ip]
  end

  def hubbyname?(name)
    return @hubs[name] if @hubs.has_key? name
    return nil
  end

  def hubbyip(ip)
    @hubs.each_value{|hub| return hub if hub.socket.peeraddr[3]==ip}
    return nil
  end

  def wanted_file?(nick)
    return @queue.wanted_file?(nick)
  end

  def full_path?(filename,nick)
    return @queue.full_path?(filename,nick)
  end

  def which_hub?(nick)
    if @usershub.has_key? nick
      @usershub[nick]
    else
      nil
    end
  end
  def search(pattern,options)
    puts "rite"
    @hubs.each_value{|hub| 
      #puts "searching #{hub}"
      hub.search_with_options(pattern,options,@address,@extport)}
  end
  
  def passive_search(pattern,options)
    @hubs.each_value{|hub|
      puts "searching passively"
      hub.passive_search(pattern,options)	
    }
  end

  def handle_hub_event(hub, type, *args)
  end
  
  def handle_peer_event(peer, type, *args)
  end
  
  def handle_search_event(info)
    puts "MAYBE YOU SHOULD OVERRIDE SEARCH EVENT, QUEERFACE"
  end
end
