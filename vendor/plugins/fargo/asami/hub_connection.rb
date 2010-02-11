
require 'hub_parser'
require 'util'
require 'rexml/document'
require 'he3'
require 'dc_connection'
require 'bz2'

#a connection to a DCHub
class HubConnection < DCConnection
  attr_reader :config, :nick_list, :op_list, :favname, :foldermap
  attr :name
  #create a connection with this hubs config, the main program config, desired username and a ui
  def initialize(opts1, opts2, name, ui)
    super()
    @config = opts1
    @searchlist = []
    @name = name
    @nick_list = ""
    @op_list = ""
    @wantedfiles = {}
    @reverseconnects = {}
    @sharesize = 0
    @favname = name
    @ui = ui
    @list = ""
    @searchmap = {}
    @foldermap = {}
    @passives = {}
  end
  
  def method_missing(name,*args)
    puts "hub tried to call #{name} with #{args}"
  end

  def hostname
    config[:address]
  end

  def port
    config[:port]
  end

  #create the file list for this hub - the DcLst and BZ2
  def regenerate_file_list
    publish :generating_file_list
    sharedir = config[:sharedfolders]
    @list = ""
    if sharedir.nil? || sharedir.length > 0
      publish :done_generating_file_list
      return
    end

    sharedir.each{ |dir| 
      @foldermap[File.basename(dir)] = dir
      y = make_file_list dir, 0
      @list << y[0]
      @sharesize+=y[1]
    }
    x=File.new("#{@favname}.raw",File::CREAT|File::TRUNC|File::RDWR)
    begin
      File.open(File.expand_path("~/.Asami/mylists")){}
    rescue
      File.mkpath(File.expand_path("~/.Asami/mylists"))
    end
    xmllist=make_xml_list @list
    x << @list
    x.close
    bz2list=File.new(File.expand_path("~/.Asami/mylists/#{@favname}.bz2"),File::CREAT|File::TRUNC|File::RDWR)
    bz2list << BZ2::bzip2(@list)
    bz2list.close
    xmlbz2list = File.new(File.expand_path("~/.Asami/mylists/#{@favname}.xml.bz2"), File::CREAT | File::TRUNC | File::RDWR)
    xmlbz2list << BZ2::bzip2(xmllist)
    xmlbz2list.close
    #unless system "./filelist2","#{@favname}.raw",File.expand_path("~/.Asami/mylists/#{@favname}.DcLst")
    #  puts $?
    #end
    dclist = File.new File.expand_path("~/.Asami/mylists/#{@favname}.DcLst"), File::CREAT | File::TRUNC | File::RDWR
    x = he3_encode(@list)
    dclist << x
    dclist.close
    @searchmap = make_search_map @list
    @foldermap.each_key{|key| p key}
    publish :done_generating_file_list
  end

  #create the XML filelist
  def make_xml_list(list)
    doc = REXML::Document.new
    doc << REXML::XMLDecl.new
    root=REXML::Element.new "FileListing"
    root.attributes['Version']=1
    root.attributes['Generator']="Asami DC 0.2"
    doc.add_element root
    rows=[]
    
    list.each{|line|
      line.chomp!
      i=line
      i=~/^(\t*)(.*)\|(.*)|^(\t*)(.*)/
      if $1
        res1=$1
        res2=$2
      else
        res1=$4
        res2=$5
      end
      if res1.length==0
        el=nil
        if $3
          el=REXML::Element.new "File"
          el.attributes['Size']=$3
        else
          el=REXML::Element.new "Directory"
          rows[res1.length]=el
        end
        el.attributes['Name']=res2
        root.add_element el
        current=el
      else
        el=nil
        if $3
          el=REXML::Element.new "File"
          el.attributes['Size']=$3
        else
          el=REXML::Element.new "Directory"
          rows[res1.length]=el
        end
        el.attributes['Name']=res2
        rows[res1.length-1].add_element el
      end
    }
    output=""
    doc.write output
    output
  end

  # things to do after connecting
  def post_connect
    publish :connected, :hublink => self, :name => name 
    regenerate_file_list
  end

  #add our contribution to the mainchat
  def say(line)
    reply "<%s> %s", get('nick'), line
  end

  #send our info
  def send_my_info
    tags="<++V:0.02,M:"
    if get('active')
      tags << "A,H:1/0/0,S:1>"
    else
      tags << "P,H:1/0/0,S:1>"
    end
    interests = (get('interests')||"").dup
    interests << tags if get('tag')
    reply("$MyINFO $ALL %s %s$ $%s%s$%s$%d$",
          get('nick'), interests,
          get('speed'), 1.chr,
          get('email'), @sharesize)
  end

  #send an active  search with supplied options
  def search_with_options(pattern,options,ip,port)
    ss="#{options[:max]}?#{options[:min]}?#{options[:size]}?#{options[:type]}" + 63.chr + pattern.gsub(/ /,"$")
    reply "$Search %s:%d %s", ip, port, ss
  end

  #send a passive search
  def passive_search(pattern,options)
    ss="#{options[:max]}?#{options[:min]}?#{options[:size]}?#{options[:type]}" + 63.chr + pattern.gsub(/ /,"$")
    reply "$Search Hub:%s %s", get('nick'),ss
  end

  def search(pattern,port)
    ss = "F?T?0?1" + 63.chr + pattern.gsub(/ /, "$")
    address = @socket.addr[3]
    reply "$Search %s:%d %s", address, port, ss
  end

  #send either a connect to me or a revconnect to the remote_nick
  def connect_to_me(remote_nick, ip, port)
    if ip=="0.0.0.0"
      ip=@socket.addr[3]
    end
    #info "Sent connecttome %s %s:%d\n",remote_nick,ip,port
    if get('active')
      reply "$ConnectToMe %s %s:%d", remote_nick, ip, port
      #puts "sent connecttome #{ip} #{port}"
    else
      reply "$RevConnectToMe %s %s",get('nick'),remote_nick
      #puts "sent revconnect"
    end
  end

   #ask the hub for info on a user
   def get_info(remote_nick)
     reply "$GetINFO %s %s", remote_nick, get('nick')
   end

   #do we have a user in the list by this name
   def has_user?(nick)
     return true if @nick_list.include? nick
   end

   def parse_message(text)
     HubParser.parse_message text
   end
   
   def handle_message(message)
     #	puts message
     case message[:type]

     when :lock then @key = message[:key]
       reply "$Key %s", @key


     when :hubname
       #@name = message[:name]
       publish(:got_hub_name, {:name => message[:name]})
       reply "$ValidateNick %s", get('nick')

     when :hello
       if message[:who] == get('nick') then
         publish :login_done
         send_my_info
         reply "$GetNickList"
       else
         publish(:someone_logged_in, {:who => message[:who]})
       end

     when :myinfo
       publish(:info, {:nick => message[:nick],
                       :desc => message[:interest],
                       :email => message[:email],
                       :speed => message[:speed],
                       :sharesize => message[:sharesize]})

     when :privmsg
       publish(:privmsg, {:from => message[:from],
                          :text => message[:text]})
     when :chat
       publish(:chat, {:from => message[:from],
                       :text => message[:text]})

     when :connect_to_me
       puts "connect to me received"
       publish(:connect_to_me,{:ip=>message[:ip],:port=>message[:port],:hub => self})

     when :denide
       publish :denide

     when :nick_list
       @nick_list = message[:nicks]
       publish :got_nick_list

     when :passive_search_result
       publish(:passive_search_result,{:nick=>message[:nick],:path=>message[:path],
                                       :size=>message[:size],:totalslots=>message[:totalslots],:openslots=>message[:openslots],
                                       :hubname=>message[:hubname]})

     when :getpass
       reply("$MyPass %s",get('pass'))

     when :badpass
       puts "OH"

     when :op_list
       @op_list = message[:nicks]
       publish :got_op_list

     when :quit
       publish(:quit, {:who => message[:who]})

     when :searchresult
       publish(:searchresult, {:nick => message[:who],:path=>message[:file],
                               :totalslots=>message[:total],:openslots=>message[:open],:size=>message[:size],
                               :hubname=>message[:hubname]})


       #
       # TODO: Neither of these search replies verify the size or filetype
       #
     when :active_search
       if message[:pattern].length > 3  
         smessage=message[:pattern].gsub(/\$/," ")
         @searchmap.each_key{|key|
           if key.include? smessage
             s = UDPSocket.new
             info=@searchmap[key]
             resp = sprintf("$SR %s %s\005%s %d/%d\005%s %s:%s",get('nick'),File.join(info[0],key),info[1].to_s,@ui.upslots,get('uploadslots'),@name,get('address'),get('port'))
             s.send(resp,0,message[:ip],message[:port])
           end
         }
       end


     when :pasv_search
       if message[:pattern].length > 3
         smessage=message[:pattern].gsub(/\$/," ")
         @searchmap.each_key{|key|
           if key.include? smessage
             info=@searchmap[key]
             reply "$SR %s %s\005%s %d/%d\005%s (%s)\005%s",get('nick'),File.join(info[0],key),info[1].to_s,@ui.upslots,get('uploadslots'),@name,get('address'),message[:searcher]
           end
         }
       end


     when :revconnect
       puts "revconnect received"
       @passives[message[:who]]=true
       #	publish(:revconnect,{:nick => message[:who]})
       if get('active')
         if @ui.usershub[message[:who]]==nil || @ui.usershub[message[:who]]==self
           @ui.usershub[message[:who]]=self
           connect_to_me(message[:who],@ui.address,@ui.extport)
         end
       else
         reply("$RevConnectToMe %s %s",get('nick'),message[:who]) unless @passives[message[:who]]
       end

     when :mystery then publish(:mystery, {:text => message[:text]})
     when :junk    then nil
     when :disconnected
       publish(:disconnected)
     else
       # warning "Ignoring `%s'\n", message.inspect
     end
   end
 end
