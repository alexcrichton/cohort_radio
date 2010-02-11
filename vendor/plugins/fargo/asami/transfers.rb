#the list of currently going transfers that occupies the bottom of the main window
class Transfers<Gtk::Frame
  #attr :label
  attr :button
  attr_reader :icons
  def initialize(ui)
    @ui=ui
    @name="Transfers"
    @transferlist = GenericView.new(["","User","File","Rate","Progress","Remaining"],false,true)
    @transferstore = @transferlist.model
    @connections = []
    super()
    @icons = {  :upload => @transferlist.render_icon(:'gtk-go-down',Gtk::IconSize::MENU,"transfer_up_icon"),
              :download => render_icon(Gtk::Stock::GO_UP,Gtk::IconSize::MENU,"transfer_down_icon")}
    #No I can't remember why they're backwards but I'm vaguely sure there was a good reason
    #set_homogeneous(false)
    @menu = Gtk::Menu.new
    cancel_item=Gtk::MenuItem.new("Cancel Transfer")
    pause_item=Gtk::MenuItem.new("Pause Transfer")
    pm_item=Gtk::MenuItem.new("Message User")
    search_item=Gtk::MenuItem.new("Search for alternates")
    limit_item=Gtk::MenuItem.new("Change rate limit")
    @menu.append(pause_item)
    @menu.append(cancel_item)
    @menu.append(pm_item)
    @menu.append(search_item)
    @menu.append(limit_item)
    @menu.show_all
    @scrollwin = Gtk::ScrolledWindow.new()
    @scrollwin.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    @transferlist.signal_connect("button_press_event") do |widget,event|
      if event.kind_of? Gdk::EventButton
        if (event.button ==3)
          @menu.popup(nil,nil,event.button,event.time)
        end
      end
    end 
    pause_item.signal_connect("activate") do
      iter=@transferlist.selection.selected
      if iter&&iter[1]
        name=iter[1]
        @ui.queue.pausedownload iter[1]
      end
    end
    cancel_item.signal_connect("activate") do
      iter=@transferlist.selection.selected
      if iter
        name=iter[1]
        transfer=@ui.transfers.index iter
        if transfer==nil||transfer.direction==:download
          @ui.queue.canceldownload iter[2] if iter[2]
          @ui.queueview.removefile iter[1] if iter[1]
        else
          transfer.cancel
        end
      end
    end
    pm_item.signal_connect("activate") do
      iter=@transferlist.selection.selected
      if iter
        hub = @ui.transfers[iter].hub
        @ui.addpm(iter[1],"",hub,hub.get('nick')) if hub
      end
    end
    limit_item.signal_connect("activate") do 
      iter=@transferlist.selection.selected
      if iter
        ratedia=Gtk::Dialog.new("Set new limit",nil,nil,[Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_REJECT],[Gtk::Stock::OK,Gtk::Dialog::RESPONSE_ACCEPT])
        ratespinna=Gtk::SpinButton.new 1,9999,1
        ratespinna.value = @ui.transfers.index(iter).rate
        ratespinna.width_chars=5
        ratedia.signal_connect("response") do |widget,response|
          if response=Gtk::Dialog::RESPONSE_OK
            @ui.transfers.index(iter).rate=ratespinna.value_as_int
            puts "new rate set: #{ratespinna.value_as_int}"
          end
          ratedia.destroy
        end
        ratehbox=Gtk::HBox.new
        ratehbox.pack_start Gtk::Label.new("Max Rate"),true,true,3
        ratehbox.pack_start ratespinna,false,false,3
        ratehbox.pack_start Gtk::Label.new("KB/Second"),true,true,3
        ratedia.vbox.pack_start ratehbox,false,false,6
        ratedia.show_all
      end
    end
    @timer=Gtk::timeout_add(1000){update}
    @scrollwin.add(@transferlist)
    add(@scrollwin)
    @rows=[]
    show_all
  end
  def addtransfer(name,file,connection)
    @connections << connection unless @connections.include? connection
    x=@transferstore.append
    x[1]=name
    x[2]=file
    x
  end
  #set the direction of a transfer in this list
  def setdir(x,dir)
    x[0]=@icons[dir]
  end
  def geticon(adir)
    @icons[dir]
  end
  def removetransfer(iter,connection)
    #x=@transferstore.get_iter(reference.path) if reference&&reference.path
    #@transferstore.remove(x) if x
    if @connections.delete connection
      @transferstore.remove(iter) if iter
    end
  end
  def setmybook(lol)
    @notebook=lol
  end
  def update
    @connections.each{|connection|
      x=@ui.transfers[connection]
      next unless x && connection.downloading
      connection.time=connection.time+1
      bps=sprintf("%.2f",(connection.chunksize.to_f/connection.time)).to_f
      x[3]="#{human_readable_size(bps)}/s" if bps
      x[4]=sprintf("%s/%s (%.2f%%)",human_readable_size(connection.downloaded),human_readable_size(connection.file_length),100*connection.downloaded.to_f/connection.file_length)
      x[5] = human_readable_time(((connection.file_length-connection.downloaded)/bps).to_i) if bps&&bps!=0
    }
  end
end
