#the tab that holds a filelist
class FileListTab<Gtk::VBox
  attr :button
  #create a new tab out of the raw list the tab is passed
  def initialize(name,hub,ui)
    @name=name
    @filelist=GenericView.new(%w(Filename Size),true)
    @filesstore=@filelist.model
    @hub = hub
    @ui=ui
    super()
    set_homogeneous(false)
    @scrollwin = Gtk::ScrolledWindow.new()
    @scrollwin.add(@filelist)
    pack_start(@scrollwin)
    @rows=[]
    @filelist.signal_connect("row_activated")do|huh,path,col|
      x=@filesstore.get_iter(path)
      filename=""
      while x do
        filename = x[0] +"\\"+filename
        x=x.parent
      end
      filename.chop!
      x=@filesstore.get_iter(path)
      if x.has_child?
        download_dir(x,filename)
      else
        @ui.download_file(@name,filename,@hub,nil)
      end
    end
    show_all
  end
  def download_dir(row,path)
    a=row.first_child
    while(a)
      if(a.has_child?)
        download_dir(a,path+"\\"+a[0])
      else
        @ui.download_file(@name,path+"\\"+a[0],@hub,path)
      end
      break unless a.next!
    end
  end
  def makelist(list)
    @file = list
    @file.each{|line|
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
        x=@filesstore.append(nil)
        x[0]=res2
        x[1]=$3.to_i if $3
        @rows[0]=x
      else
        x=@filesstore.append(@rows[res1.length-1])
        x[0]=res2
        x[1]=human_readable_size $3.to_i if $3
        @rows[res1.length]=x
      end
    }
  end
=begin
  def makexmllist(xmllist)
    @doc=REXML::Document.new xmllist
    @doc.elements.each("FileListing/Directory"){|dir|
      x=@filesstore.append(nil)
      x[0]=dir.attributes["Name"]
      procxmldir(dir,x)
    }
  end
  def procxmldir(element,row)
    element.elements.each("Directory"){|dir| 
      x=@filesstore.append(row)
      x[0]=dir.attributes["Name"]
      procxmldir(dir,x)
    }
    element.elements.each("File"){|file|
      x=@filesstore.append(row)
      x[0]=file.attributes["Name"]
      x[1]=human_readable_size(file.attributes["Size"].to_i)
    }
  end
=end
def makexmllist(xmllist)
    @doc=REXML::Document.new xmllist
    procxmldir(@doc.elements[1],nil)
  end
 def procxmldir(element,row)
    element.elements.each{|e|
        a=e.name
        x=@filesstore.append(row)
        x[0]=e.attributes["Name"]
        if a[0]==70
                x[1]=human_readable_size(e.attributes["Size"].to_i)
        else
                procxmldir(e,x)
        end
    }
 end
  def setmybook(lol)
    @notebook=lol
  end
end
