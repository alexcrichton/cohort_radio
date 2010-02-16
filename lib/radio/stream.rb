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
      @playing_thread.exit if @playing_thread
      @playing_thread = nil

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
      @playing_thread && @playing_thread.alive?
    end
    
    def paused?
      !playing?
    end
    
    def play
      return if playing? || !connected?
      @playing_thread.wakeup if @playing_thread && @playing_thread.stop?
      @song_thread.wakeup if @song_thread && @song_thread.stop?
    end
    
    def pause
      return if paused? || !connected?
      if @playing_thread.alive? 
        @playing_thread.stop
      else 
        @song_thread.stop
      end
    end
    
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
      stream_next
      
      # while streaming, set the next song. Don't want database calls slowing down
      # listeners...
      set_next
      
      # Wait for the song to finish streaming. It'll wake us up when it's done. If not...
      # well we're screwed
      sleep
      
    end
    
    def update_song queue_item
      queue_item.song.update_attributes(:play_count => queue_item.song.play_count + 1)
      playlist.queue_items.delete queue_item
    end
    
    def stream_next
      # Get the song information, then set it to nil so we know to reset it.
      song, metadata, queue_item = @next_song
      @next_song = nil
      
      @playing_thread = Thread.start {
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
        @song_thread.wakeup
      }
    end
    
    def random_song
      ids = Song.select(:id).map &:id
      Song.find(ids[rand(ids.size)])
    end
    
  end
  
end