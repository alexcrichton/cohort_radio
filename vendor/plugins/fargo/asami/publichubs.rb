require 'net/http'
#a list of public hubs
class PublicHubs<Gtk::VBox
  attr :button
  attr_writer :ui
  def initialize
    @name="Public Hubs"
    @pubslist = GenericView.new(%w(Name Description Users Address),false)
    @pubsstore = @pubslist.model
    super()
    set_homogeneous(false)
    @scrollwin = Gtk::ScrolledWindow.new()
    @scrollwin.add(@pubslist)
    @scrollwin.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    pack_start(@scrollwin)
    @rows=[]
    @pubslist.signal_connect("row_activated")do|huh,path,col|
      x=@pubsstore.get_iter(path)
      makehub(x)
    end
    hbox=Gtk::HBox.new
    hbox.pack_start(Gtk::Label.new("Public Hublist URL"),false,false,6)
    @button=Gtk::Button.new("List hubs")
    entry=Gtk::Entry.new
    entry.set_activates_default true
    @button.can_default=true
    @button.signal_connect("clicked"){
      @pubsstore.clear
      refreshlist(entry.text)
    }
    hbox.pack_start(entry,true,true,6)
    hbox.pack_start(@button,false,false,6)
    pack_end(hbox,false,false,6)
    show_all
  end
  #fetch the list of public hubs and populate the list
  def refreshlist(url)
    url=~/^(.*?)\/(.*)/
    backgroundedly do
      list=nil
      begin
        x=Net::HTTP.start($1)
        list = x.get("/#{$2}").body
      rescue
        list=nil
        puts "error fetching hublist"
      end
      if list
        list.each{|line|
          line=~/^(.*?)\|(.*?)\|(.*?)\|(.*?)\|\|\|\|\|/
          y=@pubsstore.append
          y[0]=$1
          y[1]=$3
          y[2]=$4
          y[3]=$2
        }
      end
    end
  end
  #connect to a public hub from the list
  def makehub(x)
    @ui.addhubwithoutconfig(x[0],x[3])
  end
end
