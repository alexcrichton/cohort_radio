class Radio
  
  class Stream < Shout
    
    BLOCKSIZE = (1 << 16).freeze
    
    @@tag_recoder = Iconv.new("utf-8", 'utf-8')
    
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
      
      Rails.logger.info "Stream: #{playlist.name} disconnecting"
      
      @loop = false
      
      if @song_thread
        Rails.logger.debug "Stream: #{playlist.name} joining with the song thread"
        @next = true
        @song_thread.wakeup
        @song_thread.join
        @song_thread = nil
      end

      @queue_items_to_update << nil unless @queue_items_to_update.empty?
      Rails.logger.debug "Stream: #{playlist.name} joining with the update thread"
      @update_thread.join if @update_thread
      @update_thread = nil

      @queue_items_to_update.clear
      @next_song = nil
      @current_song = nil
      
      super if connected?
    end
    
    def next
      @next = true
      @song_thread.wakeup if @song_thread
      true
    end
    
    def playing?
      !@playing_pid.nil?
    end
    
    def paused?
      !playing?
    end
    
    def next_song
      # was disconnected sometimes...
      ActiveRecord::Base.verify_active_connections! 
      
      playlist.queue_items true # force loading from the database
      
      playlist.queue_items.delete @next_song[2] if @next_song && @next_song[2]
      
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
      song, metadata, queue_item = next_song

      @current_song = song
      
      self.metadata = metadata

      stream_song song.audio.path

      @queue_items_to_update << queue_item
    end
    
    def update_song queue_item
      return if queue_item.nil?
      ActiveRecord::Base.verify_active_connections!
      queue_item.song.update_attributes(:play_count => queue_item.song.play_count + 1)
      playlist.queue_items.delete queue_item
    end
    
    def stream_song path
      Rails.logger.debug "Stream: #{name} - playing file #{path}"
      
      file = File.open(path)
      @next = false
      while !@next && data = file.read(BLOCKSIZE)
      	self.send data
        Rails.logger.debug "Stream: #{name} - Block sent"
        
        # self.sync # this is stupid, freezes the entire process. Do by hand:
        d = self.delay
        Rails.logger.debug "Sleeping: #{d}"
        break if d < 0
        sleep d.to_f / 1000
      end
    end
    
    def random_song
      if playlist.pool.songs.count > 0
        ids = playlist.pool.songs
      else
        ids = Song
      end
      ids = ids.select(:id).map &:id
      
      Song.find ids[rand(ids.size)]
    end
    
  end
  
end