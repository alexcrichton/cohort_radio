class Radio
  
  class Stream < Shout
    
    BLOCKSIZE = 1 << 16
    
    @@tag_recoder = Iconv.new("utf-8", 'windows-1251')
    
    attr_accessor :options
    
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
      self.mount        = "/#{playlist.slug}-development"
      self.mount        = "/#{playlist.slug}"                   if Rails.env.production?
      self.name         = "#{playlist.name} - Development"
      self.name         = playlist.name                         if Rails.env.production?
      self.description  = playlist.description                  if playlist.description
      self.format       = Shout::MP3

      super
      
      # play songs in a different thread
      @song_thread = Thread.start { loop { play_song } }
      
      # when the songs are finished playing, update their attributes. Also remove
      # the queue_item from the playlist. Do this on a separate thread as to now slow down the
      # listeners.
      @update_thread = Thread.start { loop { update_song @queue_items_to_update.pop } }
    end
    
    def disconnect
      # Exit all threads we've got running
      Process.kill 'TERM', @playing_pid if @playing_pid
      @playing_pid = nil

      @update_thread.exit if @update_thread
      @update_thread = nil

      @song_thread.exit if @thread
      @song_thread = nil
      
      super if connected?
    end
    
    def next
      @next = true
    end
    
    def playing?
      !@playing_pid.nil?
    end
    
    def paused?
      !playing?
    end
    
    # def play
    #   return if playing? || !connected?
    #   @song_thread.wakeup if @song_thread && @song_thread.stop?
    #   true
    # end
    # 
    # def pause
    #   return if paused? || !connected?
    #   @song_thread.stop
    #   true
    # end
    
    def set_next
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
      set_next if @next_song.nil?

      # stream the song which was set to the next
      @playing_pid = fork { stream_song *@next_song }

      set_next

      Process.wait @playing_pid

    end
    
    def update_song queue_item
      queue_item.song.update_attributes(:play_count => queue_item.song.play_count + 1)
      playlist.queue_items.delete queue_item
    end
    
    def stream_song song, metadata, queue_item
      # Get the song information, then set it to nil so we know to reset it.
      Rails.logger.debug "Stream: #{name} - playing file #{song.audio.path}"
      
      self.metadata = metadata
      begin
        File.open(song.audio.path) do |file|
          while data = file.read(BLOCKSIZE)
            break if @next
          	self.send data
            Rails.logger.debug "Stream: #{name} - Block sent"
          	self.sync
          end
        end
        @next = false
      rescue => e
        Rails.logger.error "Stream: #{name} ERROR: #{e}"
        Exceptional.handle e
        disconnect
      end
      
      @queue_items_to_update << queue_item unless queue_item.nil?
    end
    
    def random_song
      ids = Song.select(:id).map &:id
      Song.find(ids[rand(ids.size)])
    end
    
  end
  
end