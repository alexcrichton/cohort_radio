class Radio
  
  class Stream < Shout
    
    BLOCKSIZE = (1 << 16).freeze
    
    @@tag_recoder = Iconv.new("utf-8", 'utf-8')
    
    attr_accessor :options
    attr_reader :current_song
    
    def initialize options = {}
      super
      self.options = options
    end
    
    def playlist_id
      options[:playlist_id]
    end
    
    def connect
      return if connected?
      
      @playlist = Playlist.find(playlist_id)
      Rails.logger.info "Stream: #{@playlist.name} connecting"

      self.host         = options[:host]
      self.port         = options[:port]                        unless options[:port].nil?
      self.user         = options[:user]                        unless options[:user].nil?
      self.pass         = options[:password] || options[:pass]  unless options[:password].nil?
      self.mount        = @playlist.ice_mount_point
      self.name         = @playlist.ice_name
      self.description  = @playlist.description                 if @playlist.description
      self.format       = Shout::MP3

      super
      
      @loop = true
      
      # play songs in a different thread
      @song_thread = Thread.start { while @loop; play_song; end }

      Rails.logger.info "Stream: #{@playlist.name} connected"
    end
    
    def disconnect
      # Exit all threads we've got running
      
      Rails.logger.info "Stream: #{@playlist.name} disconnecting"
      
      @loop = false
      
      if @song_thread
        Rails.logger.debug "Stream: #{@playlist.name} joining with the song thread"
        @next = true
        @song_thread.wakeup
        @song_thread.join
        @song_thread = nil
      end

      @current_song = nil
      
      super if connected?
    end
    
    def next
      @next = true
      @song_thread.wakeup if @song_thread
      true
    end
    
    def playing?
      @song_thread && @song_thread.alive?
    end
    
    def paused?
      !playing?
    end
    
    def next_song
      # was disconnected sometimes...
      ActiveRecord::Base.verify_active_connections! 
      
      # Get a fresh copy of the playlist
      playlist = Playlist.find(playlist_id)
      
      queue_item = playlist.queue_items.first
      song = queue_item.nil? ? random_song(playlist) : queue_item.song
            
      m = ShoutMetadata.new
      m.add 'filename', @@tag_recoder.iconv(song.audio.path)
      string = song.title
      string << " (" 
      string << song.artist.name if song.artist
      string << " - "
      string << song.album.name if song.album
      string << ")"
      m.add 'song', @@tag_recoder.iconv(string)
      m.add 'artist', @@tag_recoder.iconv("#{song.artist.name}") if song.artist
      m.add 'album', @@tag_recoder.iconv("#{song.album.name}") if song.album
      
      [song, m, queue_item]
    end
    
    def play_song
      song, metadata, queue_item = next_song

      @current_song = song.title
      
      self.metadata = metadata

      stream_song song.audio.path

      update_song queue_item
    end
    
    def update_song queue_item
      return if queue_item.nil?
      ActiveRecord::Base.verify_active_connections!
      
      # Get a fresh copy of the playlist
      playlist = Playlist.find(playlist_id)
      
      queue_item.song.update_attributes(:play_count => queue_item.song.play_count + 1)
      playlist.queue_items.delete queue_item
    end
    
    def stream_song path
      Rails.logger.info "Stream: #{@playlist.name} - playing file #{path}"
      
      file, size = File.open(path), File.size(path)
      @next = false
      while !@next && data = file.read(BLOCKSIZE)
        Rails.logger.debug "Stream: #{@playlist.name} sending block...:#{connected?.inspect}"
      	self.send data
        Rails.logger.debug "Stream: #{@playlist.name} - Block sent: #{file.pos.to_f / size} #{connected?.inspect}"
        
        # self.sync # this is stupid, freezes the entire process. Do by hand:
        d = self.delay
        Rails.logger.debug "Sleeping: #{d}"
        break if d < 0
        # This source will time out after 10 sections, don't sleep over that
        sleep [d.to_f / 1000, 9.5].min
      end

      Rails.logger.info "Stream: #{@playlist.name} - done playing file #{path}"
    ensure
      file.close if file
    end
    
    def random_song playlist
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