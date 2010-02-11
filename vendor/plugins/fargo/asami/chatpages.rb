
#a base class for hubs and pms
class ChatPage<Gtk::VBox
  attr :button
  attr :name
  attr :username
  #create a new chat that sends/receives from a hub, along with it's name and mine
  def initialize(hublink,hubname,myname)
    @@ptr=Gdk::Cursor.new Gdk::Cursor::LEFT_PTR
    @@hand=Gdk::Cursor.new Gdk::Cursor::HAND2
    hubname="" unless hubname
    @name=hubname
    super()
    set_homogeneous(false)
    @linktag=Gtk::TextTag.new "link"
    @linktag.foreground="blue"
    @linktag.underline=Pango::AttrUnderline::SINGLE
    tag=Gtk::TextTag.new "myname"
    tag.foreground="red"
    @table=Gtk::TextTagTable.new
    @table.add @linktag
    @table.add tag
    @buffer=Gtk::TextBuffer.new @table
    @chatview = Gtk::TextView.new @buffer
    @chatview.signal_connect("button-press-event")do |me,event|
      a=@chatview.window_to_buffer_coords(@chatview.get_window_type(event.window),event.x,event.y)
      iter=@chatview.get_iter_at_location(a[0],a[1])
      if iter.has_tag? @linktag
        unless iter.begins_tag?(@linktag)
          iter.backward_to_tag_toggle(@linktag)
        end
        finish=iter.dup
        finish.forward_to_tag_toggle(@linktag)
        url=iter.get_text(finish)
        exec(sprintf($gconf['/desktop/gnome/url-handlers/http/command'],url)) if fork==nil
      end
    end
    @chatview.add_events(Gdk::Event::POINTER_MOTION_MASK)
    @chatview.cursor_visible=false
    @horizbox = Gtk::HBox.new
    @scrollwin = Gtk::ScrolledWindow.new
    @textentry = Gtk::Entry.new
    @button = Gtk::Button.new("Send") 
    @frame = Gtk::Frame.new
    @hublink=hublink
    @username=myname 
    @namematch=Regexp.new("(#{@username})")
    @horizbox.pack_start(@textentry,true,true,0)
    @horizbox.pack_end(@button,false,false,0)
    @frame.add(@scrollwin)
    @scrollwin.add(@chatview)
    @scrollwin.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    @chatview.editable=false
    @chatview.wrap_mode=2
    @button.can_default=true
    @textentry.activates_default=true
    show_all
    @chatwin=@chatview.get_window(Gtk::TextView::WINDOW_TEXT)
    @chatview.signal_connect_after("motion-notify-event")do |me,event|
      unless @chatwin
        @chatwin=@chatview.get_window(Gtk::TextView::WINDOW_TEXT)
      end
      a=@chatview.window_to_buffer_coords(@chatview.get_window_type(event.window),event.x,event.y)
      iter=@chatview.get_iter_at_location(a[0],a[1])
      if iter.has_tag? @linktag
        @chatwin.cursor=@@hand
      else
        @chatwin.cursor=@@ptr
      end
      pointer
    end
    @urlmatch=Regexp.new("\\b((((ht|f)tps?://)|(www|ftp)\.)[a-zA-Z0-9\.\#\@\:%&_/\?\=\~\-]+)|(#{@username})")
                         
  end
  #convert to UTF8 and stuff in the window, also 'blues' URLs
  def addchat(input)
    input=GLib.convert(input,"utf-8","iso-8859-1")
    @buffer.insert(@buffer.end_iter, input[0..input.index(" ")])
    input=input[input.index(" ")+1 .. input.length]
    input=input.gsub("&#36;","$")
    input=input.gsub("&#124;","|")
    while(@urlmatch.match(input)) do
      puts $1
      @buffer.insert(@buffer.end_iter,$`)
      if $6
        @buffer.insert(@buffer.end_iter,$6,@table.lookup("myname"))
      else
        @buffer.insert(@buffer.end_iter,$1,@table.lookup("link"))
      end
      input=$'
    end
    @buffer.insert(@buffer.end_iter,"#{input}\n")
    vadj=@scrollwin.vadjustment
    vadj.value=vadj.upper 
    vadj.value_changed
  end
end

#a Private Message
class PMChat<ChatPage
  def initialize(hublink,hubname,myname)
    super
    pack_start(@frame,true,true,0)
    pack_end(@horizbox,false,false,0)
    @button.signal_connect("clicked"){
      if @textentry.text!=""
        text=@textentry.text.gsub("$","&#36;")
        text=text.gsub("|","&#124;")
        pmout = "$To: #{@name} From: #{@username} $<#{@username}> #{text}"
        addchat("<#{@username}> #{text}")
        @hublink.reply pmout
        @textentry.text=""
      end
    }
    show_all
  end
end

#a HubChat. Much like a PM, but has a NickList
class HubChat<ChatPage
  attr_accessor :label,:nickview
  def initialize(hublink,hubname,myname,ui)
    super(hublink,hubname,myname)
    @vpane = Gtk::HPaned.new
    @vpane.position=600
    @vpane.add1(@frame)
    @frame2=Gtk::Frame.new
    @scrollwin2 = Gtk::ScrolledWindow.new
    @nickview = NickView.new(ui,myname)
    @scrollwin2.add(@nickview)
    @frame2.add(@scrollwin2)
    @vpane.add2(@frame2)
    pack_start(@vpane,true,true,0)
    pack_end(@horizbox,false,false,0)
    @button.signal_connect("clicked"){
      if @textentry.text!=""
        text=@textentry.text.gsub("$","&#36;")
        text=text.gsub("|","&#124;")
        @hublink.say text
        @textentry.text=""
      end
    }
    show_all
  end
  #enable op functions
  def hey_im_an_op
    @nickview.activate_ops
  end
  #add someone to the nicklist
  def add_user(name)
    @nickview.add_user(name)
  end
  #add details for someone to the nicklist
  def add_details(name,details)
    @nickview.add_details(name,details)
  end
  #remove user from the nicklist
  def del_user(name)
    @nickview.del_user(name)
  end
  #set the hub connection
  def hublink(link)
    @hublink=link
    @nickview.hublink(link)
  end
  #disconnect from the hub
  def disconnect
    @hublink.quit if @hublink
  end
end	
