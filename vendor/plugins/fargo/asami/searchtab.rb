#a tab to search for files from other users
class SearchTab<Gtk::HPaned
  attr_accessor :label
  attr :name
  attr :button
  attr :fileentry
  def initialize(ui)
    @ui=ui
    super()
    self.position=270
    @button = Gtk::Button.new("Search")
    @button.can_default=true
    @name="Search"
    #@frame1=Gtk::Frame.new("Search")
    @frame2=Gtk::Frame.new()
    @frame3=Gtk::Frame.new("Optional Parameters")
    @resultscroll=Gtk::ScrolledWindow.new
    @resultscroll.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
    @f1box1=Gtk::VBox.new
    @optionalbox=Gtk::VBox.new
    @fileentry=Gtk::Entry.new
    @fileentry.activates_default=true
    @sizeentry=Gtk::Entry.new
    @sizeentry.width_chars=6
    @leastradio=Gtk::RadioButton.new("At Least")
    @mostradio=Gtk::RadioButton.new(@leastradio,"At Most")
    @mblabel=Gtk::Label.new("MB")
    @results = GenericView.new(%w(User Filename Slots Size Path Hub),false)
    @resultsmodel = @results.model
    titles=["Any","Audio Files","Archives","Documents","Executables","Pictures","Videos","Folders"]
    @filetypes=[]
    @filetypes[0]=Gtk::RadioButton.new("Any")
    @typesvbox=Gtk::VBox.new
    @typesvbox.pack_start(@filetypes[0],false,false,1)
    for i in 1..7
      @filetypes[i]=Gtk::RadioButton.new(@filetypes[0],"#{titles[i]}")
      @typesvbox.pack_start(@filetypes[i],false,false,1)
    end
    @filetypes[0].active=false
    @filenamebox=Gtk::HBox.new
    @filenamebox.pack_start(Gtk::Label.new("Filename"),false,false,3)
    @filenamebox.pack_start(@fileentry,true,true,3)
    @sizemainbox=Gtk::HBox.new
    @sizemainbox.pack_start(Gtk::Label.new("Size is"),false,false,3)
    @leastmostvbox=Gtk::VBox.new
    @leastmostvbox.pack_start(@leastradio,true,true,3)
    @leastmostvbox.pack_start(@mostradio,true,true,3)
    @sizemainbox.pack_start(@leastmostvbox,false,false,3)
    @sizeentryhbox=Gtk::HBox.new
    @sizeentryhbox.pack_start(@sizeentry,true,true,3)
    @sizeentryhbox.pack_end(@mblabel,true,true,3)
    @sizemainbox.pack_end(@sizeentryhbox,true,true,3)
    @typeshbox=Gtk::HBox.new
    @typeshbox.pack_start(Gtk::Label.new("Types"),false,false,3)
    @typeshbox.pack_start(@typesvbox,true,true,3)
    @f1box1.pack_start(@filenamebox,false,true,3)
    @f1box1.pack_start(@button,false,false,3)
    @optionalbox.pack_start(@sizemainbox,false,false,3)
    @optionalbox.pack_start(@typeshbox,false,false,3)
    @frame3.add(@optionalbox)
    @f1box1.pack_start(@frame3,false,false)
    @resultscroll.add(@results)
    @frame2.add(@resultscroll)
    add1(@f1box1)
    add2(@frame2)
    @results.signal_connect("row_activated")do|huh,path,col|
      x=@resultsmodel.get_iter(path)
      filename="#{x[4]}\\#{x[1]}"
      @ui.download_file(x[0],filename,nil,nil)
    end

    show_all
  end
  #what to do if the button's clicked
  def clicked
    @resultsmodel.clear
    @ui.receiver.target=self if @ui.receiver
    if @ui.active
      @ui.search(@fileentry.text,collate_options)
    else
      @ui.passive_search(@fileentry.text,collate_options)
    end
    setname(fileentry.text)
    return fileentry.text
  end
  def set_ui(ui)
    @ui=ui
  end
  def setname(name)
    @name=name
    @label.label.set_text name
  end
  #add a search result
  def add_result(info)
    x=@resultsmodel.prepend
    x[0]=info[:nick]
    info[:path]=~/(.*)\\(.*)/
    x[1]=$2
    x[4]=$1
    x[3]=human_readable_size(info[:size].to_i) if info[:size]
    x[2]="#{info[:openslots]}/#{info[:totalslots]}"
    x[5]=info[:hub]
  end
  #similar to above, ones called by active, one by passive
  def addinfo(name,path,size,open,total,hubname)
    x=@resultsmodel.prepend
    x[0]=name
    if path=~/(.*)\\(.*)/
      x[1]=$2
      x[4]=$1
    else
      x[1]=path
    end
    x[3]=human_readable_size(size.to_i) if size
    x[2]="#{open}/#{total}"
    x[5]=hubname
    x[6]=size.to_f
  end
  #empty the results
  def clear_results
    @resultsmodel.clear
  end
  #get the options we want to search with
  def collate_options
    options={}
    if @leastradio.active?
      options[:max]="F"
      options[:min]="T"
      options[:size]=@sizeentry.text
    elsif @mostradio.active?
      options[:max]="T"
      options[:min]="F"
      options[:size]=@sizeentry.text
    end
    if options[:size]==""
      options[:max]="F"
      options[:min]="T"
      options[:size]="0"
    end
    i=0
    options[:type]=1
    @filetypes.each{|option|
      options[:type]=i+1 if option.active?
      i=i+1
    }
    options
  end
end	
