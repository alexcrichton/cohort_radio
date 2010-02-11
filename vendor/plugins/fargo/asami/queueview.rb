#tab to show the state of the queue
class QueueView<Gtk::VBox
  #attr :label
  attr :button
  attr_reader :icons
  attr_accessor :window
  #create the view from the supplied queue
  def initialize(inputqueue)
    @name="Queue"
    @queuelist = GenericView.new(%w(File Users Status Size),true)
    @queuelist.selection.mode=Gtk::SELECTION_MULTIPLE
    @queuestore = @queuelist.model
    @queue=inputqueue
    super()
    set_homogeneous(false)
    @scrollwin = Gtk::ScrolledWindow.new()
    @scrollwin.add(@queuelist)
    pack_start(@scrollwin)
    @lists=@queuestore.append nil
    @lists[0]="Filelists"
    @queue.files.each_key{|key|
      x=nil
      if key=~/.DcLst/
        x=@queuestore.append @lists
      else
        row=nil
        if @queue.files[key].downloadtarget!=nil
          @queuestore.each{|model,path,iter|
            if iter&&iter[0]==@queue.files[key].downloadtarget
              row=iter
            end
          }
          unless row
            row=@queuestore.append(nil)
            row[0]=@queue.files[key].downloadtarget
          end
        end
        x=@queuestore.append row
      end
      x[0]=key
      users=""
      @queue.files[key].sources.each{|source|
        users << "#{source[0]},"
      }
      x[1]=users.chop!
      if @queue.files[key].state==:paused
        x[2]="Paused"
      else
        x[2]="Offline"
      end
      x[3]=human_readable_size @queue.files[key].size.to_i
    }
    @menu = Gtk::Menu.new
    cancel_item=Gtk::MenuItem.new("Cancel Download")
    pause_item=Gtk::MenuItem.new("Pause Download")
    resume_item=Gtk::MenuItem.new("Resume Download")
    search_item=Gtk::MenuItem.new("Search for alternate sources")
    @menu.append(pause_item)
    @menu.append(cancel_item)
    @menu.append(resume_item)
    @menu.append(search_item)
    @menu.show_all
    @queuelist.signal_connect("button_press_event") do |widget,event|
      if event.kind_of? Gdk::EventButton
        if (event.button ==3)
          #iter=@queuelist.selection.selected
          #unless (iter&&iter[0]=="Filelists")
          @menu.popup(nil,nil,event.button,event.time)
          #end
        end
      end
    end 
    pause_item.signal_connect("activate") do
      @queuelist.selection.selected_each{|m,p,iter|
        if iter && iter[0] && iter[0]!="Filelists"
          @queue.pausedownload iter[0]
          changestatus(iter[0],"Paused")
        end
      }
    end
    resume_item.signal_connect("activate") do
      @queuelist.selection.selected_each{|m,p,iter|
        if iter && iter[0]&& iter[0]!="Filelists"
          changestatus(iter[0],"Offline") if @queue.resumedownload iter[0]
        end
      }
    end
    cancel_item.signal_connect("activate") do
      toremove=[]
      @queuelist.selection.selected_each{|m,p,iter|
        if iter&&iter[0]&& iter[0]!="Filelists"
          toremove << iter
        end
      }
      toremove.each{|iter|
        if iter.has_child?
          removedir iter
          @queuestore.remove iter
        else
          @queue.canceldownload iter[0]
          @queuestore.remove iter
        end
      }
    end
    search_item.signal_connect("activate") do
      tosearch=nil
      @queuelist.selection.selected_each{|m,p,iter|
        tosearch=iter
      }
      if tosearch && tosearch[0] && tosearch[0]!="Filelists"
        x=@window.addsearch
        x.fileentry.text=tosearch[0]
        x.clicked
      end
    end
    show_all
  end
  #add a new source for a file
  def addsource(name,file)
    @queuestore.each{|model,path,iter|
      if iter[0]==file
        iter[1] << ",#{name}"
        break;
      end
    }
  end
  # add a new file to the queueview (adding it to the queue itself is presumed already done)
  def add_file(name,file,dir)
    file="#{name}.DcLst" if file=="MyList.DcLst"
    if file=~/.DcLst/
      x=@queuestore.append @lists
      x[0]=file
      x[1]=name
      return
    end
    unless dir
      @queuestore.each{|model,path,iter|
        if iter&&iter[0]==file
          iter[1] << ",#{name}"
          return
        end
      }
      x=@queuestore.append nil
      x[0]=file
      x[1]=name
    else
      row=nil
      @queuestore.each{|model,path,iter|
        if iter&&iter[0]==dir
          row=iter
        end
      }
      unless row
        row=@queuestore.append(nil)
        row[0]=dir
      end
      x=@queuestore.append(row)
      x[0]=file
      x[1]=name
    end
  end
  #remove a file from the queueview
  def removefile(filename)
    @queuestore.each{|model,path,iter|
      if path&&iter&&iter[0]==filename
        if iter.has_child?
          removedir iter
          break
        else
          @queuestore.remove iter
          break
        end
      end
    }
  end
  def removedir(dir)
    backgroundedly do
    a=dir.first_child
    while(a)
      if(a.has_child?)
        removedir(a)
      else
        @queue.removefile a[0]
      end
      break unless a.next!
    end
    end
  end
  #change the shown state of a queue item since a user has joined
  def userjoined(name)
    @queuestore.each{|model,path,iter|
      if iter && iter[1]&&iter[1].include?(name)
        iter[2]="Waiting" if iter[2]=="Offline"
      end
    }
  end
  #remove a user from a file's sources
  def remove_user(file,user)
    @queuestore.each{|model,path,iter|
      if iter&&iter[0]==file
        users=iter[1].split(',')
        users.delete user
        str=""
        users.each{|user|str<< "#{user},"}
        str.chop!
        iter[1]=str
      end
    }
  end
  #change the state of a file in the queue
  def changestatus(filename,newstatus)
    @queuestore.each{|model,path,iter|
      if iter&&iter[0]==filename
        iter[2]=newstatus
        break;
      end
    }
  end
end
