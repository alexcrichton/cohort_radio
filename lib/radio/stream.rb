class Radio
  
  class Stream < Shout
    
    BLOCKSIZE = 1 << 16
    
    @@tag_recoder = Iconv.new("utf-8", 'windows-1251')
    
    attr_accessor :options
    attr_reader :current_song
    
    def initialize options = {}
      super
      self.options = options
      @queue_items_to_update = Queue.new
    end
    
    def playlist
      options[:playlist]
    end
    
    def connect
      return if connected?

      self.host         = options[:host]
      self.port         = options[:port]                        unless options[:port].nil?
      self.user         = options[:user]                        unless options[:user].nil?
      self.pass         = options[:password] || options[:pass]  unless options[:password].nil?
      self.mount        = playlist.ice_mount_point
      self.name         = playlist.ice_name
      self.description  = playlist.description                  if playlist.description
      self.format       = Shout::MP3

      super
      
      @loop = true
      
      # play songs in a different thread
      @song_thread = Thread.start { while @loop; play_song; end }
      
      # when the songs are finished playing, update their attributes. Also remove
      # the queue_item from the playlist. Do this on a separate thread as to now slow down the
      # listeners.
      @update_thread = Thread.start { while @loop; update_song @queue_items_to_update.pop; end }
    end
    
    def disconnect
      # Exit all threads we've got running
      
      @loop = false
      
      Process.kill 'USR1', @playing_pid rescue nil
      @song_thread.join if @song_thread
      @song_thread = nil

      @queue_items_to_update << nil unless @queue_items_to_update.empty?
      @update_thread.join if @update_thread
      @update_thread = nil

      Process.wait @playing_pid rescue nil
      @playing_pid = nil
      
      @queue_items_to_update.clear
      @next_song = nil
      @current_song = nil
      
      super if connected?
    end
    
    def next
      # See the stream_song method as to why
      Process.kill 'USR1', @playing_pid if @playing_pid
    end
    
    def playing?
      !@playing_pid.nil?
    end
    
    def paused?
      !playing?
    end
    
    def set_next delete = false
      # was disconnected sometimes...
      ActiveRecord::Base.verify_active_connections! 
      
      playlist.queue_items true # force loading from the database
      
      playlist.queue_items.delete @next_song[2] if delete && @next_song && @next_song[2]
      
      # force loading from the database
      queue_item = playlist.queue_items.first
      song = queue_item.nil? ? random_song : queue_item.song
            
      m = ShoutMetadata.new
      m.add 'filename', @@tag_recoder.iconv(song.audio.path)
      if song.title
        m.add 'song', @@tag_recoder.iconv("#{song.title} (#{song.artist} - #{song.album})")
      else
        m.add 'song', @@tag_recoder.iconv(File.basename(song.audio.path))
      end
      m.add 'artist', @@tag_recoder.iconv("#{song.artist}") if song.artist
      m.add 'album', @@tag_recoder.iconv("#{song.album}") if song.album
      
      @next_song = [song, m, queue_item]
    end
    
    def play_song
      # set_next if @next_song.nil?

      set_next true

      song, metadata, queue_item = @next_song

      # We have to for because Shout's sync method freezes the entire process.
      # This is obviously undesireable for the entire process, but it'll work 
      # if we put it in its own process.
      @current_song = song
      
      @playing_pid = Process.fork { stream_song song, metadata, queue_item }


      # wait for the process to exit. Once it's exited, we've finished playing this song.
      Process.wait @playing_pid if @playing_pid

      @queue_items_to_update << queue_item

    end
    
    def update_song queue_item
      return if queue_item.nil?
      ActiveRecord::Base.verify_active_connections! # 
      queue_item.song.update_attributes(:play_count => queue_item.song.play_count + 1)
      playlist.queue_items.delete queue_item
    end
    
    def stream_song song, metadata, queue_item
      # Get the song information, then set it to nil so we know to reset it.
      Rails.logger.debug "Stream: #{name} - playing file #{song.audio.path}"
      
      self.metadata = metadata
      begin
        File.open(song.audio.path) do |file|
          Signal.trap("USR1") { 
            $_song_pass = true
          }
          while !$_song_pass && data = file.read(BLOCKSIZE)
          	self.send data
            Rails.logger.debug "Stream: #{name} - Block sent"
          	self.sync
          end
        end
      rescue => e
        Rails.logger.error "Stream: #{name} ERROR: #{e}"
        Exceptional.handle e
        # disconnect
      end
      
    end
    
    def random_song
      ids = Song.select(:id).map &:id
      Song.find ids[rand(ids.size)]
    end
    
  end
  
end