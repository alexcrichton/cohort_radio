require 'util.rb'
require 'pathname'

#class to represent a file we want
class WantedFile
  attr_accessor :size,:progress,:state,:sources,:downloadtarget
  #create  a new file available from source where source is a username
  def initialize(source)
    @sources=[source]||[]
    @state=:idle
    @size=0
    @downloadtarget=nil
  end
  #move the front of the queue to the back
  def totheback
    @sources.push @sources.shift if @sources.length > 0 
  end
  #get the next user we can get this file from (if there is one)
  def nextuser
    @sources[0]
  end
end

#the files we want to download
class DownloadQueue
  attr_accessor :busy,:files,:wanted
  
  def method_missing(name, *args)
    puts "Queue tried to call #{name} with #{args}"
  end
  
  def initialize(numslots,ui,config)
    @slots=numslots
    @busy={}
    @ui=ui
    @queue_path=Pathname.new(File.expand_path("~/.Asami/queue"))
    @queue=load_queue
    @queue['files'].each_value{|file| file.state=:idle unless file.state==:paused}
    #puts "ok"
    @files=@queue['files']||{}
    @wanted=@queue['wanted']||{}
    @thread=Thread.new do
      while true do
        #puts "Queue thread going"
        @busy.each_key{|key|
          if @busy[key]==:idle
            #puts "checking for files from #{key}"
            f=wanted_file? key
            f=f[0] if f
            @ui.find_user(key).each{|hub|
              #puts "trying for #{f} from #{hub}"
              hub.connect_to_me(key,@ui.address,@ui.extport)
            } 
          end
        }
        sleep 120
      end
    end
  end
  
  #get the queue off disk
  def load_queue
    if @queue_path.readable?
      @queue_path.open("r") { |stream|
        YAML::load stream
      }
    else
      queue={}
      queue['files']={}
      queue['wanted']={}
      queue
    end
  end
  
  #save the queue to disk
  def save_queue
    @queue['files']=@files
    @queue['files'].each_value{|file| file.state=:idle unless file.state==:paused}
    @queue['wanted']=@wanted
    @queue_path.open(File::CREAT|File::TRUNC|File::RDWR, 0644) { |stream|
      stream << @queue.to_yaml
    }
  end
  
  #add a download slot
  def incrementslots
    @slots+=1
  end
  
  #get the list of wantedfiles
  def getqueue
    @files
  end
  
  #check if we want this file and if we're not already getting it
  def wanted_file?(name)
    (@wanted[name]||[]).each{|file|
      return [file,@files[file].downloadtarget] if @files[file]&&@files[file].state==:idle
    }
    return nil
  end
  
  #get the full path we need to ask for for this filename if we're trying to get it from user
  def full_path?(filename,user)
    file=File.basename(filename.gsub("\\","/"))
    if y=@files[file]
      y.sources.each{|source|
        return source[2] if source[0]==user
      }
    end
  end
  
  #add a file to the queue from name, hub, by fullpath
  def addtoqueue(fullpath,name,hub,dir)
    @wanted[name]=[] unless @wanted[name] #priqueue here?
    filename=File.basename fullpath.gsub('\\','/')
    @wanted[name].push(filename) unless @wanted[name].include? filename
    if @files[filename]
      @files[filename].sources.push [name,hub,fullpath] unless @files[filename].sources.include? [name,hub,fullpath]
    else
      @files[filename]=WantedFile.new [name,hub,fullpath]
      @files[filename].downloadtarget=dir
    end
    @busy[name]=:idle unless @busy.has_key? name
    save_queue
  end
  
  #remove 'file' from queue
  def removefile(file)
    unless @files[file]
      file=file.gsub("xml.bz2","DcLst")
      file=file.gsub("bz2","DcLst")
    end
    return unless @files[file]
   # puts "removing #{file}"
   # puts "#{@files[file]} there?"
    @files[file].sources.each{|source|
      #puts "removing #{source}'s link to it"
      if @wanted[source[0]]
        @wanted[source[0]].delete file 
        @wanted.delete(source[0]) if @wanted[source[0]].length==0
        @busy[source[0]]=:idle if (@busy[source[0]]==file)
        end
      }
      @files.delete file
     # puts "removed"
      save_queue
  end
  
  #remove a user
  def removeuser(user)
    @wanted[user].each{|file|@files[file].sources.delete user}
    @wanted.delete user if @wanted[user].length==0
    save_queue
  end
  
  def removeuserfromfile(user,file)
    unless @files[file]
      file=file.gsub("xml.bz2","DcLst")
      file=file.gsub("bz2","DcLst")
    end
    return unless @files[file]
    #puts "removing #{user} as source for #{file}"
    @file[file].sources.each{|source|
      @files[file].sources.delete source if source[0]==user
    }
    @wanted[user].delete(file) if @wanted[user]
    @wanted.delete(user) if @wanted[user].length==0
  end
  
  #someone has joined, check to see if we want anything from them
  def userjoined(name,hub)
    if @wanted[name]
     # puts "#{name} joined"
      viable=false
      @wanted[name].each{|file|
        if @files[file]&&@files[file].state==:idle
          viable=true
          break;
        end
      } if @busy[name]==:idle
      @busy[name]=:idle unless @busy.has_key? name
      hub.connect_to_me(name, @ui.address, @ui.extport) if viable 
    end
  end
  
  #someone has quit, reset their state
  def userquit(name)
    @busy.delete name
  end
  
  #spot the possible future feature
  def changepriority(file,name,wanted)
  end
  
  #set some state details
  def downloadstarted(file,user)
    @busy[user]=file
    @files[file].state=:running if @files[file]
  end
  
  #take a finished download off a queue
  def downloadfinished(file,user)
    removefile(file)
  end
  
  #we've been disconnected, so set this user to idle since they can't possibly be busy anymore
  def disconnected(file,user,hub)
    @busy[user]=:idle
    @files[file].state=:idle if @files[file]
  end
  
  #bother this person again
  def tryagain(file,user,hub)
    break unless @files[file]
    @files[file].totheback
    nextuser=@files[file].nextuser
    while @busy.has_key? nextuser && @busy[nextuser]!=:idle
      @files[file].totheback
      nextuser=@files[file].nextuser
    end
    hub.connect_to_me(nextuser,@ui.address,@ui.extport)
  end
  
  #pause this download
  def pausedownload(filename)
    if @files[filename]&&@files[filename].state==:running
      @files[filename].sources.each{|source|
        if @busy[source[0]]==filename
          @ui.connections[filename].cancel
          break;
        end
      }
      @files[filename].state=:paused
      save_queue
    end
  end
  
  #cancel the download.
  def canceldownload(filename)
    if @files[filename]&&@files[filename].state==:running
      @files[filename].sources.each{|source|
        if @busy[source[0]]==filename
          @ui.connections[source[0]].cancel if @ui.connections[source[0]]
        end
      }
    end
    removefile filename
  end
  
  #resume a paused download
  def resumedownload(filename)
    false unless @files[filename]&&@files[filename].state==:paused
    @files[filename].state=:idle
    save_queue
  end
  
  #much like disconnected
  def noslots(file,user)
    @busy[user]=:idle
    @files[file].state=:idle if @files[file]
  end
  
  def setstate(file,newstate)
    @files[file].state=newstate if @files[file]
  end
	
  def setsize(file,size)
    @files[file].size=size if @files[file]
  end
	
  def setprog(file,progress)
    @files[file].progress=progress if @files[file]
  end

  def prodthread
    @thread.wakeup
  end

end
