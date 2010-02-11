require 'gtk2'
# a connection and hub settings dialog
class ConnectDialog<Gtk::Dialog
  attr_reader :current,:config
  def initialize(config)
    @config=config
    @current=nil
    super("Connect To Hub",nil,nil,[Gtk::Stock::APPLY,Gtk::Dialog::RESPONSE_APPLY],[Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_REJECT],["C_onnect",Gtk::Dialog::RESPONSE_ACCEPT])
    @sharesize=0
    set_size_request 600,455
    mainbox=Gtk::HBox.new
    @notebook = Gtk::Notebook.new
    rightbox=Gtk::VBox.new false,6
    hubsframe=Gtk::Frame.new "Hubs"
    hubsframe.set_size_request 200,0
    @hubsstore=Gtk::ListStore.new String
    @hubslist=Gtk::TreeView.new @hubsstore
    @hubslist.reorderable=true
    mycol = Gtk::TreeViewColumn.new("Hubs",Gtk::CellRendererText.new,:text=>0)
    @hubslist.append_column mycol
    @hubslist.headers_visible=false
    hframebox=Gtk::VBox.new
    hframehbox=Gtk::HBox.new
    @addhubbutton=Gtk::Button.new "Add _Hub"
    @addhubbutton.signal_connect("clicked"){|button|
     do_add
    }
    @remhubbutton=Gtk::Button.new "_Remove Hub"
    @remhubbutton.signal_connect("clicked"){|button|
     do_rem
    }
    hframehbox.pack_start @addhubbutton,true,true,3
    hframehbox.pack_start @remhubbutton,true,true,3
    hframebox.pack_start hframehbox,false,false,6
    hframebox.pack_start(Gtk::ScrolledWindow.new.add(@hubslist).set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC),true,true,3)
    hubsframe.add hframebox

    @menu = Gtk::Menu.new
    addhub_item =Gtk::MenuItem.new("Add a new hub")
    removehub_item=Gtk::MenuItem.new("Remove hub")
    @menu.append(addhub_item)
    @menu.append(removehub_item)
    @menu.show_all
    @hubslist.signal_connect("button_press_event") do |widget,event|
      if event.kind_of? Gdk::EventButton
        if (event.button ==3)
          @menu.popup(nil,nil,event.button,event.time)
        end
      end
    end
    addhub_item.signal_connect("activate") do
      do_add
    end
    removehub_item.signal_connect("activate") do
     do_rem
      
    end

### details sections
    @addressframe=Gtk::Frame.new "Connect to hub at"
    @detailsframe=Gtk::Frame.new "Provide these details"
    @addressframe.shadow_type=Gtk::SHADOW_NONE
    @detailsframe.shadow_type=Gtk::SHADOW_NONE
    detailsbox=Gtk::VBox.new false,3
    hbox=Gtk::HBox.new 
    @address=Gtk::Entry.new
    @port=Gtk::Entry.new
    @port.width_chars=5
    @username=Gtk::Entry.new
    @password=Gtk::Entry.new
    @password.visibility=false
    @interests=Gtk::Entry.new
    @downloadfolder=Gtk::Entry.new
    @email=Gtk::Entry.new
    @hubslist.selection.signal_connect("changed"){|sel|
      if sel.selected
        if @current
          @config['hubs'][@current]['address']=@address.text
          @config['hubs'][@current]['port']=@port.text
          @config['hubs'][@current]['nick']=@username.text
          @config['hubs'][@current]['pass']=@password.text
          @config['hubs'][@current]['interests']=@interests.text
          @config['hubs'][@current]['downloadtarget']=@downloadfolder.text
          @config['hubs'][@current]['sharedfolders']=@folderslist.get_folders
          @config['hubs'][@current]['sharesize']=@folderslist.sharesize
          @config['hubs'][@current]['autoconnect']=@connectcheck.active?
          @config['hubs'][@current]['uploadrate']=@uploadrate.value_as_int
          @config['hubs'][@current]['downloadrate']=@downloadrate.value_as_int
          @config['hubs'][@current]['disconnect']=@disconnect.active?
          @config['hubs'][@current]['tag']=@check.active?
          @config['hubs'][@current]['email']=@email.text
        end
        @sharesize=0
        @current=sel.selected[0]
        hub=@config['hubs'][sel.selected[0]]||{}
        @address.text=hub['address']||""
        @port.text=hub['port']||"411"
        @username.text=hub['nick']||@config['nick']||""
        @password.text=hub['pass']||@config['pass']||""
        @interests.text=hub['interests']||@config['interests']||""
        @downloadfolder.text=hub['downloadtarget']||@config['downloadtarget']||""
        toshare=hub['sharedfolders']||@config['sharedfolders']||[]
        @connectcheck.active=hub['autoconnect']
        @check.active=hub['tag']
        @disconnect.active=hub['disconnect']
        @downloadrate.value=hub['downloadrate']||0
        @uploadrate.value=hub['uploadrate']||0
        @email.text=hub['email']||@config['email']||""
        @folderslist.clear
        @folderslist.set_folders toshare
        reactivate
      else
        @current=nil
        deactivate
      end
    }
    @hubslist.signal_connect("row-activated"){|s,p,c|
      response Gtk::Dialog::RESPONSE_ACCEPT
    }
    aframevbox=Gtk::VBox.new
    sg=Gtk::SizeGroup.new Gtk::SizeGroup::HORIZONTAL
    label=Gtk::Label.new("Hub Address:")
    sg.add_widget label
    label.xalign=1
    hbox.pack_start(label,false,true,3)
    hbox.pack_start(@address,true,true,3) 
    aframevbox.pack_start(hbox,false,false,3)
    hbox=Gtk::HBox.new
    label=Gtk::Label.new("Hub Port:")
    sg.add_widget label
    label.xalign=1
    hbox.pack_start(label,false,true,3)
    hbox.pack_start(@port,true,true,3)
    aframevbox.pack_start(hbox,false,false,3)
    @addressframe.add(aframevbox)
    sg=Gtk::SizeGroup.new Gtk::SizeGroup::HORIZONTAL
    hbox=Gtk::HBox.new
    label=Gtk::Label.new("Name:")
    sg.add_widget label
 label.xalign=1
    hbox.pack_start label,false,false,3
    hbox.pack_start @username,true,true,3
    detailsbox.pack_start(hbox,false,false,3)
    hbox=Gtk::HBox.new
    label=Gtk::Label.new("Password:")
    sg.add_widget label
 label.xalign=1
    hbox.pack_start label,false,false,3
    hbox.pack_start @password,true,true,3
    detailsbox.pack_start(hbox,false,false,3)
    hbox=Gtk::HBox.new
    label=Gtk::Label.new("Interests:")
    sg.add_widget label
    label.xalign=1
    hbox.pack_start label,false,false,3
    hbox.pack_start @interests,true,true,3
    detailsbox.pack_start(hbox,false,false,3)
    hbox=Gtk::HBox.new
    label=Gtk::Label.new("")
    sg.add_widget label
    @check = Gtk::CheckButton.new "Append information tag to interests"
    hbox.pack_start label,false,false,3
    hbox.pack_start @check,true,true,3
    detailsbox.pack_start hbox,false,false,3
    hbox=Gtk::HBox.new
    label=Gtk::Label.new("Email:")
    sg.add_widget label
    label.xalign=1
    hbox.pack_start label,false,false,3
    hbox.pack_start @email,true,true,3
    detailsbox.pack_start(hbox,false,false,3)
    @detailsframe.add detailsbox
   @downloadframe=Gtk::Frame.new "Download Files From This Hub To"
    @browse=Gtk::Button.new "_Browse"
    @browse.signal_connect("clicked") do
      if @current
        folderselect =Gtk::FileChooserDialog.new("Select a folder to share", nil, 
                                                 Gtk::FileChooser::ACTION_SELECT_FOLDER,
                                                 "gnome-vfs",
                                                 [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT],
                                                 [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
                                                 )
        folderselect.signal_connect("response"){|w,l|
          if l=Gtk::Dialog::RESPONSE_ACCEPT
            fpath=folderselect.filename
            @downloadfolder.text=fpath
          end
          folderselect.destroy
        }
        folderselect.show
      end
    end
    @downloadframe.add Gtk::HBox.new.pack_start(@downloadfolder,true,true,3).pack_start(@browse,false,false,3)
    @downloadframe.shadow_type=Gtk::SHADOW_NONE
    @ratesframe=Gtk::Frame.new("Default Transfer Rate Limits (0=no limit)")
    @ratesframe.shadow_type=Gtk::SHADOW_NONE
    hbox=Gtk::HBox.new
    hbox.pack_start(Gtk::Label.new("Upload"),false,false,3)
    @uploadrate=Gtk::SpinButton.new(0.0,9999.0,1.0)
    hbox.pack_start(@uploadrate,false,false,3)
    hbox.pack_start(Gtk::Label.new("KB/s     Download"),false,false,3)
    @downloadrate=Gtk::SpinButton.new(0.0,9999.0,1.0)
    hbox.pack_start(@downloadrate,false,false,3)
    hbox.pack_start(Gtk::Label.new("KB/s"),false,false,3)
    @ratesframe.add hbox

    @folderslist=FolderList.new "Folders To Share With This Hub"
    @folderslist.shadow_type=Gtk::SHADOW_NONE
    @connectcheck=Gtk::CheckButton.new "Connect to this hub on startup"
    @disconnect=Gtk::CheckButton.new "Disconnect users from this hub when leaving hub"
    rightbox.pack_start @addressframe,false,false,3
    rightbox.pack_start @detailsframe,false,false,3
    rightbox.pack_start @downloadframe,false,false,3
    #rightbox.pack_start @ratesframe,false,false,3
    #rightbox.pack_start @disconnect,false,false,3
    #rightbox.pack_start @folderslist,true,true,3
    hbox=Gtk::HBox.new
    hbox.pack_start @connectcheck,true,true,3
    rightbox.pack_start hbox,true,true,3
    @notebook.append_page rightbox,Gtk::Label.new("Details")
    @notebook.append_page @folderslist,Gtk::Label.new("Shares")
    mainbox.pack_start hubsframe,false,false,6
    mainbox.pack_start @notebook

    vbox.add mainbox
    @config['hubs'].each_key{|key|
      x=@hubsstore.append
      x[0]=key
    }
    deactivate
    @hubslist.selection.select_iter @hubsstore.iter_first if @hubsstore.iter_first
    show_all
  end
  
  #desensitize the setting widgets for when we don't have a hub selected
  def deactivate
    [@detailsframe,@downloadframe,@folderslist].each do |widget|
      widget.sensitive=false
    end
  end
  #sensitize the setting widgets for when we have a hub
  def reactivate
    [@detailsframe,@downloadframe,@folderslist].each do |widget|
      widget.sensitive=true
    end
  end
  
  #stop the timeouts, grab the folders we've selected
  def clean_up
    @config['hubs'][@current]['sharedfolders']=@folderslist.get_folders if @current
    @folderslist.stop_timeouts
  end
  
  #return the config set by this dialog
  def config
    @config['hubs'][@current]['address']=@address.text
    @config['hubs'][@current]['port']=@port.text
    @config['hubs'][@current]['nick']=@username.text
    @config['hubs'][@current]['pass']=@password.text
    @config['hubs'][@current]['interests']=@interests.text
    @config['hubs'][@current]['downloadtarget']=@downloadfolder.text
    @config['hubs'][@current]['sharedfolders']=@folderslist.get_folders
    @config['hubs'][@current]['sharesize']=@folderslist.sharesize
    @config['hubs'][@current]['autoconnect']=@connectcheck.active?
    @config['hubs'][@current]['uploadrate']=@uploadrate.value_as_int
    @config['hubs'][@current]['downloadrate']=@downloadrate.value_as_int
    @config['hubs'][@current]['disconnect']=@disconnect.active?
    @config['hubs'][@current]['tag']=@check.active?
    @config
  end
  
  def do_add
    addhub=Gtk::Dialog.new("Add Hub",nil,nil,[Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_REJECT],[Gtk::Stock::OK,Gtk::Dialog::RESPONSE_ACCEPT])
    hubname=Gtk::Entry.new
    hubname.activates_default=true
    hubaddress=Gtk::Entry.new
    hubaddress.activates_default=true
    hubport=Gtk::Entry.new
    hubport.activates_default=true
    hubport.width_chars=5
    hubport.text="411"
    addhub.default_response=Gtk::Dialog::RESPONSE_ACCEPT
    addhub.vbox.pack_start(Gtk::HBox.new.pack_start(Gtk::Label.new("Hub Name:"),false,false,3).pack_start(hubname,true,true,3))
    addhbox=Gtk::HBox.new
    addhbox.pack_start(Gtk::Label.new("Address:"),false,false,3)
    addhbox.pack_start(hubaddress,true,true,3)
    addhbox.pack_start(Gtk::Label.new("Port"),false,false,3)
    addhbox.pack_start(hubport,true,true,3)
    addhub.vbox.pack_start(addhbox,true,true,3)
    addhub.show_all
    addhub.signal_connect("response"){|w,l|
      if l==Gtk::Dialog::RESPONSE_ACCEPT
        if hubname.text&&hubname.text!=""
          unless @config['hubs'][hubname.text]
            @config['hubs'][hubname.text]={} 
            @hubsstore.append[0]=hubname.text
          end
          @config['hubs'][hubname.text]['address']=hubaddress.text
          @config['hubs'][hubname.text]['port']=hubport.text
        end
      end
      addhub.destroy
    }
    addhub.show
  end
  def do_rem
    i=@hubslist.selection.selected
    if i
      @config['hubs'].delete i[0]
      @hubsstore.remove i
      @address.text=""
      @port.text=""
      @password.text=""
      @downloadfolder.text=""
      @interests.text=""
      @username.text=""
      @email.text=""
      @current=nil
      @folderslist.clear
      @sharesize=0
    end
  end

end



if $0==__FILE__
  require 'pathname'
  require 'yaml'
  require '../asami/gtkcomponents.rb'
  $config_path = Pathname.new(File.expand_path("~/.Asami/config"))
  begin
    File.open(File.expand_path("~/.Asami")){}
  rescue
    File.mkpath(File.expand_path("~/.Asami"))
  end

  def human_readable_size(bytes)
    return "0B" if bytes < 1
    bytes=bytes.to_f
    units = ['B','KB', 'MB', 'GB', 'TB']
    exponent = Math.log(bytes) / Math.log(1024)
    b=(bytes / (1024 ** exponent.floor))
    b=sprintf("%.2f",b.to_f)
    (b + units[exponent])
  end

  def du(dir, level)
    stat = File.lstat(dir)
    total = stat.blocks

    if stat.mode & 0170000 == 040000
      Dir.foreach(dir) do |file|
        next if file =~/^\./
        f = File.join(dir,file)
        total +=
                if File.ftype(f)=="directory"
                  du(f, level + 1)
                else
                  File.size(f)
                end
      end
    end
    total
  end

  def load_config
    if $config_path.readable?
      $config_path.open("r") { |stream|
        YAML::load stream
      }
    else
      config={}
      config['hubs']={}
      config['default']={}
      config['hubs']['NewHub']={}
      config['nick']=ENV['USERNAME']
      config['speed']="56Kbps"
      config['interests']="nothing"
      config['active']=false
      config['useextip']=false
      config['default']['extip']=""
      config['extport']="1414"
      config['shared directory']=""
      config['hubs']['NewHub']['address']="dcserver.org"
      config['hubs']['NewHub']['port']="411"
      config
    end
  end
  Gtk.init
  config=load_config
  a=ConnectDialog.new config
  a.show
  Gtk.main
end
