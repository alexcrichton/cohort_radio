
require 'gtk2'
#require 'gconf2'

require 'socket'
require 'monitor.rb'

require 'thread.rb'

require 'util.rb'
require 'key_generator.rb'
require 'dc_connection.rb'
require 'hub_connection.rb'
#require 'client_connection.rb'
require 'active_client_connection.rb'
require 'ui.rb'
require 'gtkcomponents.rb'
require 'searchtab.rb'
require 'hubdialog.rb'
require 'chatpages.rb'
require 'flist_tab.rb'
require 'transfers.rb'
require 'publichubs.rb'
require 'downloadqueue.rb'
require 'queueview.rb'
require 'mdi.rb'

Gtk.init

#$gconf = GConf::Client.new

class Gtk::MDI::Document
  def item=(item)
    @item=item
  end
  def item
    @item
  end
  def widget
    @widget
  end
  def icon=(id)
    @label.icon=id
  end
  def highlightlabel
    @label.markup="<span color='Blue'>#{@label.text}</span>"
  end
  def unhighlightlabel
    @label.markup="#{@label.text}"
  end
end

class Gtk::MDI::NotebookLabel
  def markup=(str)
    @label.markup=str
  end
end

class Gtk::MDI::Controller
  def which_window?(document)
    @windows.each{|window|
      return window if window.notebook.documents.include? document
    }
  end
end

#A class for the windows created when a tab is dragged out of a notebook
class MDIWindow<Gtk::Window
  attr_reader :notebook, :box,:mainpane,:viewmenu
  attr_accessor :closes
  @@queuedoc,@@downdoc,@@updoc,@@pubsdoc,@@searchdoc,@@favdoc,@@ui=nil
  def method_missing(name, *args)
    puts "MDI Window tried to call #{name} with #{args}"
  end
  def initialize
    super
    @closes=true
    @box=Gtk::VBox.new
    @mainpane=Gtk::VPaned.new
    @notebook=Gtk::MDI::Notebook.new
    @menubar=Gtk::MenuBar.new
    @filemenu=Gtk::Menu.new
    @toolsmenu=Gtk::Menu.new
    @viewmenu=Gtk::Menu.new
    @helpmenu=Gtk::Menu.new
    file_item=Gtk::MenuItem.new "File"
    help_item=Gtk::MenuItem.new "Help"
    view_item=Gtk::MenuItem.new "View"
    tools_item=Gtk::MenuItem.new "Tools"
    @menubar.append(file_item)
    @menubar.append(tools_item)
    @menubar.append(view_item)
    @menubar.append(help_item)
    options_item=Gtk::ImageMenuItem.new Gtk::Stock::PREFERENCES
    options_item.signal_connect("activate"){
      prefs=GlobalPrefs.new(@config) unless prefs;
      prefs.signal_connect("response"){|w,l|
        if l == Gtk::Dialog::RESPONSE_ACCEPT
          config=prefs.get_results
          unless config['active']
            @active=false
            #stoplistener
          else
            @active=true
            if config['useextip']
              @address=config['extip']
              @extport=config['extport']
            end
          end
        end
        save_config(config)
        prefs.destroy
      }	
    }
    quit_item=Gtk::ImageMenuItem.new Gtk::Stock::QUIT
    quit_item.signal_connect("activate"){
      @@ui.quit if @@ui
    }
    conn_item=Gtk::ImageMenuItem.new "Connect"
    conn_item.image=Gtk::Image.new.set(:'gtk-jump-to',Gtk::IconSize::MENU)
    conn_item.signal_connect("activate"){
      connectdialog=ConnectDialog.new @@ui.config
      connectdialog.signal_connect("response"){|dialog,response|
        connectdialog.clean_up
        connectdialog.hide
        hubtoadd=dialog.current
        if response==Gtk::Dialog::RESPONSE_ACCEPT
          save_config(dialog.config) unless dialog.config==nil
          @@ui.addhub(dialog.current,@config['hubs'][dialog.current]) if dialog.current 
        else
          config=load_config
        end
        connectdialog=nil
      }
    }
    search_item=Gtk::ImageMenuItem.new "Search"
    search_item.image=Gtk::Image.new.set(:'gtk-find',Gtk::IconSize::MENU)
    search_item.signal_connect("activate"){@@ui.latestsearch=addsearch||@@ui.latestsearch}
    pubs_item=Gtk::ImageMenuItem.new "Public Hubs"
    pubs_item.image=Gtk::Image.new.set(:'gtk-justify-fill',Gtk::IconSize::MENU)
    pubs_item.signal_connect("activate"){addpubs}
    queue_item=Gtk::ImageMenuItem.new "Queue"
    queue_item.image=Gtk::Image.new.set(:'gtk-find-and-replace',Gtk::IconSize::MENU)
    queue_item.signal_connect("activate"){addqueue}
    finisheddown_item=Gtk::ImageMenuItem.new "Finished Downloads"
    finisheddown_item.image=Gtk::Image.new.set(:'gtk-go-down',Gtk::IconSize::MENU)
    finisheddown_item.signal_connect("activate"){adddownwin}
    finishedup_item=Gtk::ImageMenuItem.new "Finished Uploads"
    finishedup_item.image=Gtk::Image.new.set(:'gtk-go-up',Gtk::IconSize::MENU)
    finishedup_item.signal_connect("activate"){addupwin}
    index_item=Gtk::ImageMenuItem.new Gtk::Stock::HELP
    about_item=Gtk::MenuItem.new "About"
    @filemenu.append(options_item)
    @filemenu.append(quit_item)
    @toolsmenu.append(conn_item)
    @toolsmenu.append(search_item)
    @toolsmenu.append(pubs_item)
    @toolsmenu.append(queue_item)
    @toolsmenu.append(finisheddown_item)
    @toolsmenu.append(finishedup_item)
    @helpmenu.append(index_item)
    @helpmenu.append(about_item)
    file_item.submenu=@filemenu
    tools_item.submenu=@toolsmenu
    view_item.submenu=@viewmenu
    help_item.submenu=@helpmenu
    @menubar.show_all
    @transferbin=Gtk::VBox.new
    @mainpane.add1 @notebook
    @mainpane.position=400
    @mainpane.border_width=6
    @box.pack_start(@menubar,false,false,0)
    @box.pack_end(@mainpane)
    add(@box)
  end
  def setconfig(config)
    @config=config
  end
  def setcontroller(controller)
    @controller=controller
  end
  #just called once to set some class variables for these windows since they all share these
  def setwidgets(queueview,upwin,downwin,ui)
    @queueview=queueview
    @downwin=downwin
    @upwin=upwin
    @@ui=ui
    @@queuedoc=Gtk::MDI::Document.new(@queueview,"Queue")
    @@queuedoc.icon=:'gtk-find-and-replace'
    @@queuedoc.widget.window=self
    @@downdoc=Gtk::MDI::Document.new @downwin,"Finished Downloads"
    @@downdoc.icon=:'gtk-go-down'
    @@updoc=Gtk::MDI::Document.new @upwin,"Finished Uploads"
    @@updoc.icon=:'gtk-go-up'
    @@pubsdoc=Gtk::MDI::Document.new PublicHubs.new,"Public Hubs"
    @@pubsdoc.icon=:'gtk-justify-fill'
  end
  def addqueue
    unless @controller.documents.include? @@queuedoc
      @notebook.add_document(@@queuedoc) 
      @@queuedoc.widget.window=self
    end
  end
  def addfavs
    @notebook.add_document(@@favdoc) unless @controller.documents.include? @@favdoc
  end
  def addpubs
    @notebook.add_document(@@pubsdoc) unless @controller.documents.include? @@pubsdoc
  end
  def addupwin
    @notebook.add_document(@@updoc) unless @controller.documents.include? @@updoc
  end
  def adddownwin
    @notebook.add_document(@@downdoc) unless @controller.documents.include? @@downdoc
  end
  def downdoc
    @@downdoc
  end
  def updoc
    @@updoc
  end
  def addsearch
    unless @controller.documents.include? @@searchdoc
      spage=SearchTab.new @@ui
      @@searchdoc=Gtk::MDI::Document.new(spage,"Search")
      @@searchdoc.icon=:'gtk-find'
      @@ui.searchpages[spage.name]=@@searchdoc
      spage.label=@@searchdoc.label
      @notebook.add_document(@@searchdoc)
      spage.button.signal_connect("clicked") do
        newname=spage.fileentry.text
        if newname&&newname!=""
          win=@@ui.which_window @@ui.searchpages[spage.name]
          if win.notebook.documents.length==1   #now this is a crappy hack
            z=Gtk::MDI::Document.new SearchTab.new("lol"),"nah"
            win.notebook.add_document z
          end
          index=win.notebook.index_of_document @@ui.searchpages[spage.name]
          win.notebook.remove_document(@@ui.searchpages[spage.name])
          spage.clicked
          x=Gtk::MDI::Document.new spage,newname
          win.notebook.add_document x
          x.icon=:'gtk-find'
          win.notebook.page=(@notebook.index_of_document x)||0
          win.notebook.shift_document x,index
          win.notebook.remove_document z if z
          @@ui.searchpages[x.title]=x
        end
      end
      spage
    end
  end
  #each window has a 'view' menu that holds the pages in the window's notebook
  def add_page_to_view_menu(page)
    puts "adding #{page.title}"
    case page.title
      
    when "Search"
      item=Gtk::ImageMenuItem.new "Search"
      page.item=item
      item.image=Gtk::Image.new.set :'gtk-find',Gtk::IconSize::MENU
      item.signal_connect("activate"){@notebook.page=@notebook.index_of_document @@searchdoc}
      @viewmenu.append(item)
      @viewmenu.show_all
      
    when "Public Hubs"
      item=Gtk::ImageMenuItem.new "Public Hubs"
      page.item=item
      item.image=Gtk::Image.new.set :'gtk-justify-fill',Gtk::IconSize::MENU
      item.signal_connect("activate"){@notebook.page=@notebook.index_of_document @@pubsdoc}
      @viewmenu.append(item)
      @viewmenu.show_all
      
    when "Finished Uploads"
      item=Gtk::ImageMenuItem.new "Finished Uploads"
      page.item=item
      item.image=Gtk::Image.new.set :'gtk-go-up',Gtk::IconSize::MENU
      item.signal_connect("activate"){@notebook.page=@notebook.index_of_document @@updoc}
      @viewmenu.append(item)
      @viewmenu.show_all
      
    when "Finished Downloads"
      item=Gtk::ImageMenuItem.new "Finished Downloads"
      page.item=item
      item.image=Gtk::Image.new.set :'gtk-go-down',Gtk::IconSize::MENU
      item.signal_connect("activate"){@notebook.page=@notebook.index_of_document @@downdoc}
      @viewmenu.append(item)
      @viewmenu.show_all
      
    when "Queue"
      # NOTE: Queue also sets 'widget.window'
      page.widget.window=self
      item=Gtk::ImageMenuItem.new "Queue"
      page.item=item
      item.image=Gtk::Image.new.set :'gtk-find-and-replace',Gtk::IconSize::MENU
      item.signal_connect("activate"){@notebook.page=@notebook.index_of_document @@queuedoc}	
      @viewmenu.append(item)
      @viewmenu.show_all
      
    else
      if page.widget.is_a? FileListTab
        puts "FILE LIST"
        item=Gtk::ImageMenuItem.new(page.title)
        page.item=item
        item.signal_connect("activate"){@notebook.page=@notebook.index_of_document page}
        item.image=Gtk::Image.new.set :'gtk-open',Gtk::IconSize::MENU
        @viewmenu.append(item)
        @viewmenu.show_all
      elsif page.widget.is_a? ChatPage
        item=Gtk::ImageMenuItem.new(page.title)
        page.item=item
        item.signal_connect("activate"){@notebook.page=@notebook.index_of_document page}
        item.image=Gtk::Image.new.set :'gtk-justify-left',Gtk::IconSize::MENU
        @viewmenu.append(item)
        @viewmenu.show_all
      elsif page.widget.is_a? SearchTab
        item=Gtk::ImageMenuItem.new(page.title)
        page.item=item
        item.signal_connect("activate"){@notebook.page=@notebook.index_of_document page}
        item.image=Gtk::Image.new.set :'gtk-find',Gtk::IconSize::MENU
        @viewmenu.append item
        @viewmenu.show_all
      end
    end
  end
  def remove_page_from_view_menu(page)
    puts "removing #{page.title}"
    @viewmenu.remove page.item
  end
  def rename_view_menu_item(oldname,newname)
    @viewmenu.children.each{|child|
      if oldname == child.children[0].label
        child.children[0].set_text newname
        break;
      end
    }
  end
end

#the main UI class, a big horrible window
class GtkUI<UI
  attr_accessor :queueview,:controller,:latestsearch,:searchpages,:transfers
  def method_missing(name,*args)
    puts "GTKUI tried to call #{name} with #{args}"
  end
  def initialize(config)
    super
    if config['active']==true
      @active=true
      if config['useextip']==true
        @address = config['extip']
        @extport = config['extport']
      else
        @address="0.0.0.0"
        @extport=0
      end
    else
      @active=false
      @address="0.0.0.0"
      @extport=0
    end
    @pagenames = Hash.new
    @hubpages = Hash.new
    @pms = Hash.new
    @queueview=QueueView.new @queue
    @upwin=FinishedView.new
    @downwin=FinishedView.new
    @searchpages=Hash.new
    @timeouts=Hash.new
    @controller=Gtk::MDI::Controller.new(MDIWindow,:notebook)
    #@controller.signal_connect('window_removed') do |controller, window, last|
    #Gtk::main_quit if last
    #end
    @controller.signal_connect('window_added') do |controller,window|
      window.setconfig config
      window.setcontroller @controller
      window.notebook.signal_connect("switch_page") do |me,newpage,oh|
        if y=window.notebook.document_at_index(oh)
          window.title=y.title + " - Asami" 
          window.set_default(y.widget.button)
          y.unhighlightlabel
        end
      end
      window.notebook.signal_connect("document_added") do |notebook,document|
        window.add_page_to_view_menu document
      end
      window.notebook.signal_connect("document_removed") do |notebook,document,last|
        window.remove_page_from_view_menu document
      end
    end
    @win=@controller.open_window
    @win.setwidgets @queueview,@upwin,@downwin,self
    
    @win.title="Asami"
    #pos=$gconf['/apps/Asami/pos']||[0,0]
    #@win.move(pos[0],pos[1])
    @win.closes=false
    @searches = Hash.new
    @transfers = Hash.new
    @mainbox = @win.box
    @toolbar = Gtk::Toolbar.new
    showtoolbar=Gtk::CheckMenuItem.new("Show Toolbar")
    #  showtoolbar.active=$gconf['/apps/Asami/toolbar']!=false
    showtoolbar.active=true
    showtoolbar.signal_connect("toggled") do
      #if $gconf['/apps/Asami/toolbar']
       # @toolbar.hide
      # $gconf['/apps/Asami/toolbar']=false
      #   else
      #    @toolbar.show
      #   $gconf['/apps/Asami/toolbar']=true
      #end
      if showtoolbar.active
        @toolbar.show
        else
        @toolbar.hide
      end
      showtoolbar.active=!showtoolbar.active
    end
    @win.viewmenu.append showtoolbar
    @latestsearch=nil
    @toolbar.icon_size=Gtk::IconSize::LARGE_TOOLBAR
    @notebook=@win.notebook
    @upshowing=false
    @downshowing=false
    
    @toolbar.append("Connect","Connect","urmom",Gtk::Image.new(:'gtk-jump-to',@toolbar.icon_size)){
      connectdialog=ConnectDialog.new config.clone
      connectdialog.signal_connect("response"){|dialog,response|
        if response==Gtk::Dialog::RESPONSE_APPLY
          @config=dialog.config
          save_config(config)
        else
          connectdialog.clean_up
          connectdialog.hide
          if response==Gtk::Dialog::RESPONSE_ACCEPT
            unless dialog.config==nil
              @config=dialog.config
              save_config(config)
            end
            addhub(dialog.current,@config['hubs'][dialog.current]) if dialog.current 
          else
            config=load_config
          end
        end
      }
    }	
    @toolbar.append("Preferences","Preferences","urmom",Gtk::Image.new.set(:'gtk-preferences',@toolbar.icon_size)){
      prefs=GlobalPrefs.new(config) unless prefs;
      prefs.signal_connect("response"){|w,l|
        if l == Gtk::Dialog::RESPONSE_ACCEPT
          config=prefs.get_results
          unless config['active']
            @active=false
            #stoplistener
          else
            @active=true
            if config['useextip']
              @address=config['extip']
              @extport=config['extport']
            end
          end
        end
        save_config(config)
        prefs.destroy
      }	
    }
    @toolbar.append("Search","Search","urmom",Gtk::Image.new.set(:'gtk-find',@toolbar.icon_size)){@latestsearch=@win.addsearch||@latestsearch}	
    @toolbar.append("Public Hubs","Public Hubs","urmom",Gtk::Image.new.set(:'gtk-justify-fill',@toolbar.icon_size)){@win.addpubs}
    @toolbar.append("Queue","Queue","urmom",Gtk::Image.new.set(:'gtk-find-and-replace',@toolbar.icon_size)){@win.addqueue}
    @toolbar.append("Finished Downloads","Show Finished Downloads","urmom",Gtk::Image.new.set(:'gtk-go-down',@toolbar.icon_size)){@win.adddownwin}
    @toolbar.append("Finished Uploads","Show Finished Uploads","urmom",Gtk::Image.new.set(:'gtk-go-up',@toolbar.icon_size)){@win.addupwin}
    
    @transpage=Transfers.new self
    @win.mainpane.add2(@transpage)
    
    @win.addqueue
    @notebook.show_all
    @mainbox.set_homogeneous(false)
    @mainbox.pack_start(@toolbar,false,false)
    @mainbox.show
 #   if $gconf['/apps/Asami/toolbar']!=false
      @toolbar.show 
  #    $gconf['/apps/Asami/toolbar']=true
   # end
    @win.set_size_request(800,600)
    @win.signal_connect("configure-event"){|win,event|
#      $gconf['/apps/Asami/pos']=@win.position
      false
    }
    @win.signal_connect_after("destroy"){
      Gtk.main_quit
    }
    @win.show
    @config['hubs'].each_key{|key|
      if @config['hubs'][key]['autoconnect']
        addhub(key,@config['hubs'][key])
      end
    }
  end
  #add a new hub to the main window
  def addhub(name,config)
    config=@config unless config
    chatpage = HubChat.new(nil,name,config['nick']||@config['nick'],self)
    hubdoc=Gtk::MDI::Document.new(chatpage,name)
    hubdoc.icon=:'gtk-justify-left'
    hubdoc.signal_connect("close") do
      hub=@hubpages.index hubdoc
      @peers.each{|peer|
        peer.hub_quitting hub
      }
      chatpage.disconnect
    end
    chatpage.label=hubdoc.label
    @notebook.add_document(hubdoc)
    @hubpages[connect_with_config(name,config)]=hubdoc
  end
  #add a public hub
  def addhubwithoutconfig(name,address)
    puts address
    puts address=~/^(.*?):(.*?)$/
    hc=connect($1,$2.to_i)
    config=hc.config
    chatpage=HubChat.new(nil,name,config['nick'],self)
    @hubpages[hc]=chatpage
    x=Gtk::MDI::Document.new(chatpage,name)
    x.signal_connect("close"){chatpage.disconnect}
    chatpage.label=x.label
    @notebook.add_document(x)
  end
  #show a filelist that we've downloaded
  def makelisttab(list,name,hub)
    backgroundedly do
    ltab=FileListTab.new(name,hub,self)
    if list=~/DcLst/
      #l = `./he3 < #{File.join(File.expand_path("~/.Asami/Filelists"),list)}`
      l=he3_decode File.new(File.join(File.expand_path("~/.Asami/Filelists"),list)).read
      ltab.makelist(l)
    elsif list=~/bz2/
      x=File.new(File.join(File.expand_path("~/.Asami/Filelists"),list)).read
      l=BZ2::bunzip2(x)
      if list=~/xml/
        puts "making xml list"
        ltab.makexmllist(l)
      else
        puts "making bzlist"
        ltab.makelist(l)
      end
    end
    x=Gtk::MDI::Document.new ltab,"#{name}'s Files"
    x.icon=:'gtk-open'
    @notebook.add_document x
    end
    #File.delete File.join(File.expand_path("~/.Asami/Filelists"),list)
  end
  #find the window a page is in
  def which_window(page)
    @controller.windows.each{|window|
      if window.notebook.documents.include? page
        return window
      end
    }
  end
  #add a new private message tab
  def addpm(name,text,hub,myname)
    x=nil
    if @pms.has_key?(name)
      x=@pms[name]
    else
      pm = PMChat.new(hub,name,myname)
      x=Gtk::MDI::Document.new(pm,name)
      x.icon=:'gtk-justify-left'
      @notebook.add_document(x)
      x.signal_connect("close")do
        @pms.delete name
      end
      #pm.addchat(text) if text!=""
      @pms[name]=x
    end
    x.widget.addchat(text) if text!=""
    x.highlightlabel unless x.notebook.page==x.notebook.page_num(x.widget)
  end
  
  #add a file to the queue, start it downloading (hopefully)
  def download_file(nick, file,hub,dir)
    @queueview.add_file nick,File.basename(file.gsub("\\","/")),dir
    super nick,file,hub,dir
  end
  
  #deal with something a hub_connection has passed up to us
  def handle_hub_event(hub, type, data)
    case type
    when :got_hub_name
      @controller.which_window?(@hubpages[hub]).rename_view_menu_item(hub.name,data[:name])
      @hubpages[hub].title=data[:name]
      @hubpages[hub].widget.name=data[:name]
      
    when :chat 
      # chat "<%s> %s\n", data[:from], data[:text]
      x=@hubpages[hub]
      x.widget.addchat("<#{data[:from]}> #{data[:text]}")
      x.highlightlabel unless x.notebook.page==x.notebook.page_num(x.widget)

    when :privmsg
      puts @hubpages[hub].widget.username
      addpm(data[:from],"<#{data[:from]}> #{data[:text]}",hub,@hubpages[hub].widget.username)

    when :disconnected
      @hubpages[hub].widget.addchat("***DISCONNECTED")
      @peers.each{|peer|
        peer.hub_quitting hub
      }

    when :mystery
    #  warning "Mystery command: %s\n", data[:text]
      
    when :login_done
      #interesting "Login done!\n"
      @hubpages[hub].widget.addchat("Logged in.")
      
    when :info
      @hubpages[hub].widget.add_details(data[:nick],[data[:desc],data[:email],data[:speed],data[:sharesize]])
      
    when :generating_file_list
      #info "Generating file list... "
      
    when :done_generating_file_list
      # interesting "done!\n"
      
    when :peer_connection
      # interesting("Connected to peer %s on %d!\n",data[:ip], data[:port])
      #     data[:connection].subscribe { |type, *args|
      #		handle_peer_event(data[:connection], type, *args)
      #}
      #data[:connection].listen
      
    when :connect_to_me
      interesting("%s:%s sent us a ConnectToMe", data[:ip],data[:port])
      if @iptohub[data[:ip]]==data[:hub]||@iptohub[data[:ip]]==nil
        @iptohub[data[:ip]]=data[:hub] 
        connection = ActiveClientConnection.new(self,@config)
        connection.hub=hub
        connection.direction=:download
        connection.connect(data[:ip], data[:port])
        connection.subscribe { |type, *args| handle_peer_event(connection, type, *args)}
        #connection.listen
      end
      
    when :got_nick_list
      a=@hubpages[hub].widget
      a.nickview.needlist=false
      hub.nick_list.each do |nick|
        a.add_user(nick)
        hub.get_info(nick)
        @queue.userjoined(nick,hub)
        @queueview.userjoined(nick)
      end if hub.nick_list
      @queue.prodthread

    when :connected
      @hubpages[data[:hublink]].widget.hublink data[:hublink]
      
    when :got_op_list
      #interesting "Logged in ops: "
      @hubpages[hub].widget.hey_im_an_op if hub.op_list.include? hub.get('nick')
      #hub.op_list.sort.each do |nick|
      #  info "%s ", nick
      # end

    when :revconnect
      
      
    when :someone_logged_in
      @hubpages[hub].widget.add_user(data[:who])
      #@queue.userjoined(data[:who],hub)

    when :quit
      @hubpages[hub].widget.del_user(data[:who])
      @queue.userquit(data[:who])

    when :denide
      @hubpages[hub].widget.addchat("Your nick is in use")

    when :passive_search_result
      @latestsearch.addinfo data[:nick],data[:path],data[:size],data[:open],data[:total],data[:hubname]
     # @receiver.results << 
      
    else
      warning("Unhandled hub event %s: %s\n", type, data.inspect)
    end
  end
  #deal with something the search_receiver has passed to us
  def handle_search_event(info)
    @latestsearch.add_result(info)
  end

  #deal with something another client has passed to us
  def handle_peer_event(peer, type, data)
    Gtk::timeout_remove @timeouts[peer] if @timeouts[peer]
    case type
    when :nick
      if @transfers[peer]
        @transpage.removetransfer(@transfers[peer],peer)
        @transfers.delete @transfers[peer]
      end
      @transfers[peer]=@transpage.addtransfer(peer.remote_nick,data[:file],peer)
      #x=@transpage.get_iter @transfers[peer]
      x=@transfers[peer]
      x[4]="Connecting" if x
      #@connections[nick]=peer
      @timeouts[peer]=Gtk::timeout_add(5000){
        puts "calling initial timeout from :nick"
        peer.disconnect;false;}

    when :direction
      #y=@transpage.get_iter @transfers[peer]
      y=@transfers[peer]
      y[0]=@transpage.icons[data[:direction]] if y
            @timeouts[peer]=Gtk::timeout_add(5000){
        puts "calling timeout from :direction"
peer.disconnect;false;}

    when :get
      #y=@transpage.get_iter @transfers[peer]
      y=@transfers[peer]
      y[2]=File.basename(data[:path]) if y
            @timeouts[peer]=Gtk::timeout_add(5000){
  puts "calling timeout from :get"
peer.disconnect;false;}

    when :send_request
      #info("%s says `Send!'.  I shall obey, lest the Vile Moderators ban me!\n",peer.remote_nick)
      
    when :wrote
      #info("Sent %d bytes to %s.\n", data[:chunksize],peer.remote_nick)
      #y=@transpage.get_iter @transfers[peer]
      y=@transfers[peer]
      bps = ((data[:chunksize]/data[:taken])).to_f
      if y
        y[3] = "#{human_readable_size(bps)}/s"
        y[4] = sprintf("%s/%s (%.2f%%)",human_readable_size(data[:done]),human_readable_size(data[:size]),100*data[:done].to_f/data[:size])
        y[5] = human_readable_time(((data[:size]-data[:done])/bps).to_i)
      end
            @timeouts[peer]=Gtk::timeout_add(5000){peer.disconnect;false;}

    when :write_error
      #interesting "%s cancelled or something.\n", peer.remote_nick
      
    when :disconnected
      interesting "Disconnected from %s.\n", peer.remote_nick
      if peer.has_slot?
        release_slot
        peer.has_slot=false
      end
      y=@transfers[peer]
      #y=@transpage.get_iter x
      if data[:direction]==:download
        @queue.disconnected(data[:file],peer.remote_nick,data[:hub]) if data[:file]!=""
        @queueview.changestatus(data[:file],"Waiting")
      end
      if y
        y[4]="Disconnected" unless y[4]=="No Slots Available"
        name=y[1]
        filename=y[2]
        Gtk::timeout_add(5000){
          @transpage.removetransfer(y,peer);
          @transfers.delete(peer);
          @peers.delete(peer);
          peer=nil;
          false}
      end
      
    when :noslots
      #y=@transpage.get_iter @transfers[peer]
      x=@transfers[peer]
      y[4]="No Slots Available" if y
      @transfers.delete peer.remote_nick
        #   @timeouts[peer]=Gtk::timeout_add(5000){peer.disconnect;false;}

    when :downloadstart
      file=data[:file]
      if data[:file]=~/#{peer.remote_nick}\.(DcLst|bz2|xml\.bz2)/
        file="#{peer.remote_nick}.DcLst"
      end
      @queue.downloadstarted(file,peer.remote_nick)
      #y=@transpage.get_iter @transfers[peer]
      y=@transfers[peer]
      y[2]=data[:file] if y
      @queueview.changestatus(file,"Downloading")
      @queue.setsize(file,data[:size])
      #@transfers[peer]=@transpage.addtransfer peer.remote_nick,data[:file],0
      #interesting "Starting to download from %s\n", peer.remote_nick

    when :downloaded_chunk
      bps = sprintf("%.2f",(data[:chunksize])).to_f
      #y=@transpage.get_iter @transfers[peer]
      y=@transfers[peer]
      if y
        y[3] = "#{human_readable_size(bps)}/s" if bps!=0
        y[4] = sprintf("%s/%s (%.2f%%)",human_readable_size(data[:done]),human_readable_size(data[:size]),100*data[:done].to_f/data[:size])
        #	puts "size: #{data[:size]} done: #{data[:done]} bps: #{bps}"
        y[5] = human_readable_time(((data[:size]-data[:done])/bps).to_i) if bps!=0
      end
      
    when :upload_complete
      #y=@transpage.get_iter @transfers[peer]
      y=@transfers[peer]
      if y
        y[4]="Upload Complete" 
        name=y[1]
        filename=y[2]
        Gtk::timeout_add(5000){@transpage.removetransfer(@transfers[peer],peer);@transfers.delete peer;false}
      end
      y=@upwin.view.model.append
      if y
        y[0]=Time.new.strftime "%d/%m %I:%M%p"
        y[1]=data[:path]
        y[2]=human_readable_size data[:size]
        y[3]=data[:to]
        y[4]=data[:hub].name
      end
      
    when :done_downloading
      #y=@transpage.get_iter @transfers[peer]
      y=@transfers[peer]
      if y
        y[4]="Download Complete"
        y[5]="Done"
        name=y[1]
        filename=y[2]
        @win.downdoc.highlightlabel 
        #unless @win.downdoc.notebook.page==@win.downdoc.notebook.page_num(@downwin.widget)
        x=@downwin.view.model.append
        if x
          x[0]=Time.new.strftime "%d/%m %I:%M%p"
          x[1]=data[:file]
          x[2]=human_readable_size data[:fsize]
          x[3]=data[:from]
          x[4]=data[:hub].name
        end
      end
      file=data[:file]
      if data[:file]=~/#{peer.remote_nick}\.(DcLst|bz2|xml\.bz2)/
        file="#{peer.remote_nick}.DcLst"
        makelisttab(data[:file],data[:from],data[:hub])
      end
      @queue.downloadfinished(file,peer.remote_nick)
      @queueview.removefile file
      
      Gtk::timeout_add(5000){@transpage.removetransfer(@transfers[peer],peer);@transfers.delete peer;false}
      interesting("%s from %s is done!\n",data[:file], data[:from])
#      makelisttab(data[:file],data[:from],data[:hub]) if data[:file]=="#{peer.remote_nick}.DcLst"||data[:file]=="#{peer.remote_nick}.bz2"||data[:file]=="#{peer.remote_nick}.xml.bz2"

    when :notavailable
      @queue.removeuserfromfile(data[:file],peer.remote_nick)
      @queueview.remove_user(data[:file],peer.remote_nick)
      #puts "can't get #{data[:file]} from #{peer.remote_nick}"

      when :supports

   else
      warning("Unhandled peer event %s: %s\n", type, data.inspect)
    end
  end
  #finish up, when the UI quits it's all done
  def quit
    Gtk.main_quit
  end
end


