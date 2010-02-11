require 'gtk2'

#a simpler TreeView class since I'm lazy
class GenericView<Gtk::TreeView
  attr_reader :model,:button, :columns
  #create a new GenericView, names is the column names
  #istree is a bool for if this is going to be a TreeStore or ListStore
  #firstcolumnpixbuf is a bool to indicate if the first column is a pixbuf(transfers,nicklists)
  def initialize(names,istree=false,firstcolumnpixbuf=false, extracolumndata=false)
    y=Array.new(names.length,String)
    startcol=0
    r=[]
    y[0] = Gdk::Pixbuf if firstcolumnpixbuf
    @model=nil
    y << Float
    if istree 
      @model=Gtk::TreeStore.new(*y)
    else
      @model=Gtk::ListStore.new(*y)
    end
    super(@model)
    #scoremap={71=>3,84=>4,75=>1,77=>2}
    if firstcolumnpixbuf
      r[0] = Gtk::CellRendererPixbuf.new
      mycol=Gtk::TreeViewColumn.new("#{names[0]}",r[0],:pixbuf=>0)
      mycol.resizable=true
      mycol.clickable=true
      mycol.reorderable=true
      append_column(mycol)
      startcol=1
    end
    startcol.upto(names.length-1){|i|
      r[i]= Gtk::CellRendererText.new
      mycol = Gtk::TreeViewColumn.new("#{names[i]}",r[i],:text=>i)
      mycol.resizable=true
      mycol.clickable=true
      mycol.reorderable=true
      mycol.signal_connect("clicked"){|j|
        i=names.length  if names[i]=="Shared"||names[i]=="Size"
        if @model.sort_column_id[1]==Gtk::SORT_ASCENDING && @model.sort_column_id[0]==i
          @model.set_sort_column_id(i,Gtk::SORT_DESCENDING)
        else
          @model.set_sort_column_id(i,Gtk::SORT_ASCENDING)
        end
      }
      append_column(mycol)
    }
    set_headers_visible true
    headers_clickable=true
    set_reorderable true
  end
  #does this treeview have target in column col
  def has_row(col,target)
    @model.each{|model,path,iter|
      if iter
        return true if iter[col]==target
      end
    }
    false
  end
end		

#a class for the list of users that appears on the right of the hubchat
class NickView<GenericView
  attr_accessor :needlist
  def initialize(ui,username)
    @opped=false
    @username=username
    titles = ["","Name","Description","E-mail","Speed","Shared"]
    @ui=ui
    super(titles,false,true,true)
    selection.mode=Gtk::SELECTION_MULTIPLE
    @green=Gdk::Pixbuf.new("#{$current_path}/pixmaps/green.gif")
    @blue=Gdk::Pixbuf.new("#{$current_path}/pixmaps/blue.gif")
    @red=Gdk::Pixbuf.new("#{$current_path}/pixmaps/red.gif")
    @gray=Gdk::Pixbuf.new("#{$current_path}/pixmaps/gray.gif")
    #@nicksstore = Gtk::ListStore.new(Gdk::Pixbuf, String, String, String, String,String)
    @icons = {  "56Kbps" => @blue,
              "33.6Kbps" => @blue,
              "28.8Kbps" => @blue,
              "Satellite" => @blue,
              "ISDN"			=> @green,
              "DSL"			=> @green,
              "Cable"			=> @green,
              "LAN(T1)"		=> @green,
              "LAN(T3)"		=> @green,
              "Op"			=> @red,
              "Ghost" => @gray}
    @needlist=true
=begin
       #Another sort function I have written that crashes
       #And also just plain doesn't work
       #The intent is to shuffle anyone with the "op" icon to the top/bottom of the list
       #Doesn't happen
       #@opbuf=@icons["Op"]
       #@model.set_sort_func(1){|iter1,iter2|
       #	if iter1[0]!=@opbuf && iter2[0]!=@opbuf
       #	iter1[1] <=> iter2[1]
       #	else
       #	1 if iter1[0]==@opbuf && iter2[0]!=@opbuf
       #	-1 if iter1[0]!=@opbuf && iter2[0]==@opbuf
       #	0
       #	end
       #}
=end
    @menu = Gtk::Menu.new
    pm_item =Gtk::MenuItem.new("Private Message User")
    refresh_item =Gtk::MenuItem.new("Refresh User Info")
    getlist_item=Gtk::MenuItem.new("Get File List")
    @menu.append(pm_item)
    @menu.append(refresh_item)
    @menu.append(getlist_item)
    @menu.show_all
    @names = {}
    signal_connect("button_press_event") do |widget,event|
      if event.kind_of? Gdk::EventButton
        if (event.button ==3)
          @menu.popup(nil,nil,event.button,event.time)
        end
      end
    end
    pm_item.signal_connect("activate") do
      selection.selected_each{|m,p,x|
        @ui.addpm(x[1],"",@hub,username) if x
      }
    end
    refresh_item.signal_connect("activate") do
      selection.selected_each{|m,p,x|
        @hub.reply("$GetInfo %s %s",x[1],@username) if x
      }
    end
    getlist_item.signal_connect("activate") do
      selection.selected_each{|m,p,x|
        @ui.download_file(x[1],"MyList.DcLst",@hub,nil) if x
      }
    end
  end
  #the connection for this hub
  def hublink(hub)
    @hub=hub
  end
  #activate op functions
  def activate_ops
    return if @opped
    @force_move_item=Gtk::MenuItem.new("Force Move")
    @kick_item=Gtk::MenuItem.new("Kick")
    @kick_item.signal_connect("activate") do
      iter=selection.selected
      @hub.reply("$Kick %s",iter[1]) if iter
    end
    @force_move_item.signal_connect("activate") do
      iter=selection.selected
      @hub.reply("$OpForceMove $Who:%s$Where:0.0.0.0$Msg You've been kicked, I don't know, stop being dumb.",iter[0]) if iter
    end
    @menu.append(@kick_item)
    @menu.append(@force_move_item)
    @menu.show_all
    @opped=true
  end
  #add a user to this nicklist
  def add_user(name)
    unless @names.has_key? name || !@needlist
      x=@model.prepend
      #begin
      x[1]=GLib.convert(name,"utf-8","iso-8859-1")
      #rescue
      #	x[1]="Moron"
      #end
      x[0]=@icons["Ghost"]
      @names[name]=x
    else
      ##print "bypassing premature hello"
    end
  end
  #add the details for a user
  def add_details(name,details)
    #print "details for #{name} "
    x=@names[name]
    if x
      for i in 1..3
        #begin
        #print "adding #{details[i-1]}"
        x[i+1]=GLib.convert(details[i-1],"utf-8","iso-8859-1") if details[i-1]
        #print "added"
        #rescue
        #	x[i+1]="Error"
        #end
      end
      if @hub.op_list.include? name
        x[0]=@icons["Op"]
      else
        x[0]=@icons[details[2]] if @icons.has_key? details[2]
      end
      y="0B"
      y=human_readable_size(details[3].to_i) unless details[3].to_i=="0" || details[3]==nil
      x[5]=y

      x[6]=details[3].to_f

    end
    #print " details done"
  end
  #remove user name from the list
  def del_user(name)
    @names.delete name
    @model.each{|model,path,iter|
      if iter[1]==name
        model.remove iter
        break;
      end
    }
  end
end

#a little frame that holds a list of folders to be shared with the hub
class FolderList<Gtk::Frame
  attr_reader :sharesize
  def initialize(title)
    super(title)
    @list=GenericView.new(%w(Folder Size),false)
    @sharelabel=nil
    @sharesize=0
    @timeout=nil
    @addbutton=Gtk::Button.new("A_dd Folder")
    @addbutton.signal_connect("clicked") do
      do_add
    end
    @rembutton=Gtk::Button.new("Remove _Folder") ##
    @rembutton.signal_connect("clicked") do
      do_rem
    end
    
    @menu = Gtk::Menu.new
    addfolder_item =Gtk::MenuItem.new("Add a folder")
    removefolder_item=Gtk::MenuItem.new("Remove a folder")
    @menu.append(addfolder_item)
    @menu.append(removefolder_item)
    @menu.show_all
    @list.signal_connect("button_press_event") do |widget,event|
      if event.kind_of? Gdk::EventButton
        if (event.button ==3)
          @menu.popup(nil,nil,event.button,event.time)
        end
      end
    end
    addfolder_item.signal_connect("activate") do
      do_add
    end
    removefolder_item.signal_connect("activate") do
      do_rem
      
    end

    Gtk::Drag.dest_set @list,Gtk::Drag::DEST_DEFAULT_ALL,[["text/plain",0,0]],Gdk::DragContext::ACTION_COPY|Gdk::DragContext::ACTION_MOVE

    @list.signal_connect("drag_data_received") do |w,context,x,y,data,info,time|
      puts "data dragged on"
      x=data.data.split
      x.each{|datum|
        datum=datum.chomp
        if datum=~/file:\/\/(.+?)$/
          fpath=$1
          begin
            stat=File.lstat fpath
        rescue
            stat=nil
        end
          if stat && File.executable?(fpath)
            @toremove=[]  #workaround
            needed=do_add_folder fpath
            @toremove.each{|iter| 
              @sharesize-=du(iter[0],0)
              @list.model.remove iter
            }
            if needed
              add_list_item fpath
            end
          end
        end
      }
      resetlabel
      Gtk::Drag.finish context,true,false,0
    end

    shadow_type=Gtk::SHADOW_NONE
    hbox=Gtk::HBox.new
    vbox=Gtk::VBox.new
    hbox.pack_start(@addbutton,true,true,3)
    
    listwin=Gtk::ScrolledWindow.new
    hbox.pack_start(@rembutton,true,true,3)
    listwin.add @list
    listwin.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    @sharelabel = Gtk::Label.new("Sharing #{human_readable_size(@sharesize)}")
    vbox.pack_start(hbox,false,false,3)
    vbox.pack_start(listwin,true,true,3)
    vbox.pack_start(@sharelabel,false,false,3)
   
    set_border_width 6
    add vbox
  end
  #add a folder, check to see if it's needed, etc
  def do_add_folder(fpath)
    needed=true
    @list.model.each{|widget,path,iter|
      if iter
        if iter[0]==fpath || fpath.include?(iter[0])
          needed=false
          @sharelabel.set_text("Selected folder is already shared.")
          Gtk::timeout_add(5000){resetlabel;@timeout=nil;false;} unless @timeout
        else
          @toremove << iter if iter[0].include? fpath
        end
      end
    }
    if @toremove!=[]
      @sharelabel.set_text("Some folders have been removed from this list as a parent folder of theirs has been added.")
      @timeout=Gtk::timeout_add(5000){resetlabel;@timeout=nil;false;} unless @timeout
    end
    needed
  end
  #get the list of shared folders
  def get_folders
    folders=[]
    @list.model.each{|widget,path,iter|
      if iter && iter[0]
        folders << iter[0]
      end
    }
    folders
  end
  #populate the list of folders
  def set_folders(folders)
    @sharesize=0
    folders.each{|folder|   ##
      if File.exists?(folder)&&File.directory?(folder)
        y=@list.model.append
        y[0] = folder
        size=du(folder,0)
        y[1]=human_readable_size size
        @sharesize+=size
      end
    } if folders
    resetlabel
  end
  #add an item to the list
  def add_list_item(fpath)
    y=@list.model.append
    y[0]=fpath
    size=du(fpath,0)
    y[1]=human_readable_size size
    @sharesize+=size
  end
  #set the label back to its default
  def resetlabel
    @sharelabel.set_text("Sharing #{human_readable_size(@sharesize)}") if @sharelabel
  end
  #empty the list of shared folders
  def clear
    @list.model.clear
  end
  #stop the label resetting timeout
  def stop_timeouts
    Gtk::timeout_remove @timeout if @timeout
  end
  def do_add
     folderselect=Gtk::FileChooserDialog.new("Select a folder to share", nil, 
                                              Gtk::FileChooser::ACTION_SELECT_FOLDER,
                                              "gnome-vfs",
                                              [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT],
                                              [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
                                              )
      folderselect.signal_connect("response"){|w,l|
        if l==Gtk::Dialog::RESPONSE_ACCEPT
          fpath=folderselect.filename if folderselect.filename
          @toremove=[]  #workaround
          needed=do_add_folder fpath
          @toremove.each{|iter| 
            @sharesize-=du(iter[0],0)
            @list.model.remove iter
          }
          if needed
            add_list_item fpath
          end
        end
        resetlabel
        folderselect.destroy
      }
      folderselect.show
  end
  def do_rem
    iter=@list.selection.selected
    if iter
      @sharesize-=du(iter[0],0)
      @list.model.remove iter
    end
    resetlabel
  end
end

#the globalpreferences dialog
class GlobalPrefs <Gtk::Dialog
  def initialize(config)
    super("Settings",nil,nil,[Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_REJECT],[Gtk::Stock::OK,Gtk::Dialog::RESPONSE_ACCEPT])
    @config=config
    @notebook=Gtk::Notebook.new
    @entries={}
    @sharesize=0
    @downslots = Gtk::SpinButton.new(1,99,1)
    @downslots.width_chars=2
    @upslots=Gtk::SpinButton.new(1,99,1)
    @upslots.width_chars=2
    internals = %w(nick interests email extip extport puburl downloadtarget)
    internals.each{|key|
      x=Gtk::Entry.new
      x.text=config[key] if config&&config[key]
      @entries[key]=x
    }
    @upslots.value=@config['uploadslots']||3
    @downslots.value=@config['downloadslots']||3
    x=@config['sharedfolders']||[]  ##
    @browsebutton=Gtk::Button.new("Browse")
    @browsebutton.signal_connect("clicked") do
      folderselect = Gtk::FileChooserDialog.new("Select a folder to share", nil, 
                                                Gtk::FileChooser::ACTION_SELECT_FOLDER,
                                                "gnome-vfs",
                                                [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT],
                                                [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
                                                )
      folderselect.signal_connect("response"){|w,l|
        if l=Gtk::Dialog::RESPONSE_ACCEPT
          fpath=folderselect.filename
          @entries['downloadtarget'].text=fpath
        end
        folderselect.destroy
      }
      folderselect.show
    end
    titles=["Username","Description","EMail","Speed","Active Mode","Passive Mode", "Use External IP", "Listen on Port"]
    speeds=["56Kbps","Satellite","DSL","Cable","LAN(T1)","LAN(T3)"]
    @frame1=Gtk::Frame.new "Default User Details"
    @frame2=Gtk::Frame.new "Connection Details"
    @frame3=Gtk::Frame.new "Miscellaneous Details"
    @frame1box = Gtk::VBox.new
    @frame2box = Gtk::VBox.new
    page1box = Gtk::VBox.new
    hbox=nil
    @speed=""
    0.upto(2){|i|
      label=Gtk::Label.new(titles[i])
      hbox=Gtk::HBox.new
      hbox.pack_start(label,false,false,6)
      hbox.pack_start(@entries[internals[i]],true,true,6)
      @frame1box.pack_start(hbox,true,true,6)
    }
    @frame1.add(@frame1box)
    label=Gtk::Label.new("Speed")
    menu = Gtk::Menu.new
    speeds.each{|speed|
      menu.append Gtk::MenuItem.new(speed)
    }
    menu.show_all
    @speedmenu=Gtk::OptionMenu.new
    @speedmenu.menu=menu
    @speedmenu.signal_connect("changed"){
      @speed = speeds[@speedmenu.history]
    }
    @speedmenu.set_history(speeds.index(config['speed'])) if config['speed'] && config['speed']!=''
    hbox.pack_start(@speedmenu,true,true,6)
    @activebutton = Gtk::RadioButton.new(titles[4])
    @passivebutton=Gtk::RadioButton.new(@activebutton,titles[5])
    @entries['extip'].width_chars=6
    @externalipbutton=Gtk::CheckButton.new(titles[6])
    @listenlabel=Gtk::Label.new(titles[7])
    @passivebutton.signal_connect("clicked"){
      if @passivebutton.active?
        @externalipbutton.sensitive=false
        desensitize
      else
        @externalipbutton.sensitive=true
        if @externalipbutton.active?
          resensitize
        end
      end
    }		
    @externalipbutton.signal_connect("clicked"){
      if @externalipbutton.active?
        resensitize
      else
        desensitize
      end
    }
    if config['active']==true
      @activebutton.active=true
      resensitize
      if config['useextip']!=false
        @externalipbutton.active=true
      else
        desensitize
      end
    else
      @passivebutton.active=true
      desensitize
    end
    set_border_width(12)
    hbox=Gtk::HBox.new
    hbox.pack_start(@activebutton,false,false,3)
    hbox.pack_start(@passivebutton,false,false,3)
    @frame2box.pack_start(hbox,true,true,3)
    hbox=Gtk::HBox.new
    hbox.pack_start(@externalipbutton,false,false,3)
    hbox.pack_start(@entries['extip'],true,true,3)
    @frame2box.pack_start(hbox,true,true,3)
    hbox=Gtk::HBox.new
    hbox.pack_start(@listenlabel,false,false,3)
    hbox.pack_start(@entries['extport'],false,false,3)
    @frame2box.pack_start(hbox,true,true,3)
    hbox=Gtk::HBox.new
    hbox.pack_start(Gtk::Label.new("Public Hublist URL:"),false,false,3)
    hbox.pack_start(@entries['puburl'],true,true,3)
    @frame3.add(hbox)
    @frame2.add(@frame2box)
    @frame1.shadow_type=Gtk::SHADOW_NONE
    @frame2.shadow_type=Gtk::SHADOW_NONE
    @frame3.shadow_type=Gtk::SHADOW_NONE
    page1box.pack_start(@frame1,true,true,3)
    page1box.pack_start(@frame2,true,true,3)
    page1box.pack_start(@frame3,true,true,3)
    page2box=Gtk::VBox.new
    page2box.set_homogeneous false
    frame=Gtk::Frame.new "Upload/Download Slots"
    frame.shadow_type=Gtk::SHADOW_NONE
    hbox=Gtk::HBox.new
    hbox.pack_start(Gtk::Label.new("Uploads"),false,false,3)
    hbox.pack_start(@upslots,false,false,3)
    hbox.pack_start(Gtk::Label.new("Downloads"),false,false,3)
    hbox.pack_start(@downslots,false,false,3)
    frame.set_border_width 6
    frame.add hbox
    page2box.pack_start(frame,false,false,0)
    frame=Gtk::Frame.new "Default Download Folder"
    frame.shadow_type=Gtk::SHADOW_NONE
    hbox=Gtk::HBox.new
    hbox.pack_start(@entries['downloadtarget'],true,true,3)
    hbox.pack_start(@browsebutton,false,false,3)
    frame.add hbox
    page2box.pack_start(frame,false,false,0)
    hbox=Gtk::HBox.new
    vbox2=Gtk::VBox.new
    @folderlist = FolderList.new "Default Folders Shared"
    @folderlist.set_folders @config['sharedfolders']
    page2box.pack_start(@folderlist,true,true,3)

    @notebook.append_page(page1box,Gtk::Label.new("General Setup"))
    @notebook.append_page(page2box,Gtk::Label.new("Sharing Setup"))
    vbox.add @notebook
    show_all
  end
  
  def resetlabel
    @sharelabel.set_text("Sharing #{human_readable_size(@sharesize)} with all hubs")
  end
  #collate the global config stuff
  def get_results
    @config['speed']=@speed
    @config['active']=@activebutton.active?
    @config['useextip']=@externalipbutton.active?&&@activebutton.active?
    @config['uploadslots']=@upslots.value_as_int
    @config['downloadslots']=@downslots.value_as_int
    @config['sharedfolders']=@folderlist.get_folders
    @config['sharesize']=@folderlist.sharesize
    %w(nick interests email extip extport puburl downloadtarget).each do |thing|
      @config[thing]=@entries[thing].text
    end
    @config
  end
  
  def do_add_folder(fpath)
    needed=true
    @list.model.each{|widget,path,iter|
      if iter
        if iter[0]==fpath || fpath.include?(iter[0])
          needed=false
          @sharelabel.set_text("Selected folder is already shared.")
          Gtk::timeout_add(5000){resetlabel;false;}
        else
          @toremove << iter if iter[0].include? fpath
          @config['hubs'].each_key{|key|
            (@config['hubs'][key]['sharedfolders']||[]).delete fpath
          }
        end
      end
    }
    if @toremove!=[]
      @sharelabel.set_text("Some folders have been removed from this list as a parent folder of theirs has been added.")
      Gtk::timeout_add(5000){resetlabel;false;}
    end
    needed
  end
  #used for the active/passive mode widgets
  def desensitize
    @entries['extip'].sensitive=false
    @entries['extport'].sensitive=false
    @listenlabel.sensitive=false
  end
  
  def resensitize
    @entries['extport'].sensitive=true
    @entries['extip'].sensitive=true
    @listenlabel.sensitive=true
  end
  
end

#the finished upload/download views
class FinishedView < Gtk::ScrolledWindow
  attr_reader :button,:view
  def initialize
    super
    set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    @view=GenericView.new(%w(Time Filename Size User Hub))
    add @view
    show_all
  end
end
