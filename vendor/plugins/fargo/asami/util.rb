
require 'ansicolor'

include Term::ANSIColor

module Publisher

  # add a subscriber to the list of entities to be notified by publish
  def subscribe(&subscriber)
    (@subscribers ||= []) << subscriber
  end
  
  #notify subscribed entities
  def publish(type, *info)
    if @subscribers
      @subscribers.each do |subscriber|
        if info.length == 0
          subscriber.call type, nil
        else
          subscriber.call type, info[0]
        end
      end
    end
  end
end

#convenience function to do something in a directory without affecting current working dir
def in_directory(dir)
  old = Dir.getwd
  Dir.chdir dir
  result = yield
  Dir.chdir old
  result
end

#prints a carriage return line feed
def crlf
  print "\r\n"
end

#do supplied block in background
def backgroundedly
  Thread.start { yield }
end

# Loop a block in a new thread.
def concurrent_loop
  backgroundedly do
    loop { yield }
  end
end

#do block ignoring errors
def ignore_errors
  begin
    yield
  rescue Exception
    nil
  end
end

class IO
  def each_n_bytes(n)
    until eof?
      yield(read(n))
    end
  end
end

# The functions yellow, green, red, etc. evaluate their block with the
# terminal color set appropriately.  We would like to write:
#   info "Foo %d bar", 50
# instead of
#   yellow { printf "Foo %d bar", 50 }.
# This would be trivial to do by defining a bunch of these:
#   def info(fmt, *args)
#     yellow { printf fmt, *args }
#   end
# but the code for printfing would be very duplicated.
#
# Instead, we take the _Pragmatic_Programmer_ approach, and generate
# the code from this table:
$colorings = {:info => :yellow,
              :interesting => :green,
              :warning => :red,
              :chat => :magenta,
              :hubsent => :blue}

$chat_mode = false

# This is the generator.  It is obscure and ugly, but it works.
def make_colorings
  $colorings.each do |name, color|
    method = proc do |format, *args|
      if(!$chat_mode or name == :chat)
        printer = proc { printf(format, *args) }
        send color, &printer
      end
    end
    self.class.send :define_method, name, &method
  end
end

make_colorings

#converts an number to a b/kb/mb/gb/tb string
def human_readable_size(bytes)
  return "0B" if bytes < 1
  bytes=bytes.to_f
  units = ['B','KB', 'MB', 'GB', 'TB']
  exponent = Math.log(bytes) / Math.log(1024)
  b=(bytes / (1024 ** exponent.floor))
  b=sprintf("%.2f",b.to_f)
  (b + units[exponent])
end

#converts a time to weeks/days/hours/minutes/seconds
def human_readable_time(amount)
  seconds=amount%60
  amount=(amount-seconds)/60
  minutes=amount%60
  amount=(amount-minutes)/60
  hours=amount%24
  amount=(amount-hours)/24
  days=amount%7
  weeks=(amount-days)/7
  out=""
  out << "#{weeks} weeks, " if weeks > 1
  out << "#{weeks} week, " if weeks == 1
  out << "#{days} days, " if days >1
  out << "#{days} day, " if days == 1
  out << sprintf("%02d:%02d:%02d",hours,minutes,seconds)
  out
end

#returns x tabs
def indentify(width)
  return ("\t" * width)
end

#make a raw filelist in DC style
def make_file_list(root, indent = 0)
  list=""
  totalsize=0
  list << indentify(indent)
  list << File.basename(root)
  list << "\r\n"
  entries = Dir.entries(root)
  in_directory root do
    files = []
    entries.each do |entry|
      ignore_errors {
        if File.symlink? entry
          path = File.readlink entry
        else
          path = entry
        end
        if File.ftype(path) == "directory"
          unless (entry=~/^\./)
            y=make_file_list(entry,(indent+1))
            list << y[0]
            totalsize+=y[1]
          end
        else
          unless entry=~/^\./
            files << entry
          end
        end
      }
    end
    files.each do |file|
      begin
        size = File.size file
      rescue Exception
        # The size call can fail if the entry is a broken symlink.  We
        # don't want broken stuff in the file list, so we just ignore
        # them.
      else
        if size > 0
          list << indentify(indent + 1)
          list << file
          list << "|"
          list << size.to_s
          list << "\r\n"
          totalsize += size.to_i
        end
      end
    end
  end
  [list,totalsize]
end

#get disk usage
def du(dir, level)
  begin
    stat = File.lstat(dir)
  rescue
    return 0
  end
  return 0 unless File.executable?(dir)
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

#makes a map for use in checking for requested files
def make_search_map(list)
  paths=[]
  searchmap={}
  list.each{|line|
    line=line.chomp
    next unless line=~/^(\t*)(.*)\|(.*)|^(\t*)(.*)/
    tabs= $1 || $4
    name = $2 || $5
    size = $3
    searchmap[name] = [paths[tabs.length-1],size]
    paths = [] if tabs.length==0
    if paths[tabs.length-1]
      paths[tabs.length]=File.join(paths[tabs.length-1],name)
    else
      paths[tabs.length]=name
    end
  }
  searchmap
end

def debug(str)
  puts str if $DEBUG
end
