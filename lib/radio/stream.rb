class Radio

  class Stream < Shout

    BLOCKSIZE = (1 << 16).freeze

    @@tag_recoder = Iconv.new('utf-8', 'utf-8')

    attr_accessor :options
    attr_reader :current_song

    def initialize options = {}
      super
      @options = options
    end

    def playlist_id
      options[:playlist_id]
    end

    def connect perform_setup = true
      if perform_setup
        return if connected?

        @playlist = Playlist.find(playlist_id)
        Rails.logger.info "Stream: #{@playlist.name} connecting"

        self.host         = options[:host]
        self.port         = options[:port]        unless options[:port].nil?
        self.user         = options[:user]        unless options[:user].nil?
        self.pass         = options[:password]
        self.pass       ||= options[:pass]
        self.mount        = @playlist.ice_mount_point
        self.name         = @playlist.ice_name
        self.description  = @playlist.description if @playlist.description
      end

      super()

      if perform_setup
        @loop = true

        # play songs in a different thread
        @song_thread = Thread.start { while @loop; play_song; end }

        Rails.logger.info "Stream: #{@playlist.name} connected"
      end

      true
    end

    def disconnect perform_teardown = true
      if perform_teardown
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
      end

      super() if connected?
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
      playlist   = Playlist.find playlist_id
      queue_item = playlist.queue_items.first
      song       = queue_item.present? ? queue_item.song : random_song(playlist)

      m = ShoutMetadata.new
      m.add 'filename', @@tag_recoder.iconv(song.audio.path)

      string = song.title
      string << ' ('
      string << song.artist.name if song.artist
      if song.album
        string << ' - '
        string << song.album.name
      end
      string << ')'

      m.add 'song',   @@tag_recoder.iconv(string)
      m.add 'artist', @@tag_recoder.iconv(song.artist.name) if song.artist
      m.add 'album',  @@tag_recoder.iconv(song.album.name)  if song.album

      [song, m, queue_item]
    end

    def play_song
      song, metadata, queue_item = next_song

      @current_song = song.title

      if song.flac?
        change_format Shout::OGG
      else
        change_format Shout::MP3
      end

      self.metadata = metadata

      stream_song song.audio.path

      update_song queue_item
    end

    def change_format fmt
      if self.format != fmt
        disconnect false
        self.format = fmt
        connect false
      end
    end

    def update_song queue_item
      return if queue_item.nil?
      ActiveRecord::Base.verify_active_connections!

      queue_item.song.increment! :play_count
      queue_item.destroy
    end

    def stream_song path
      Rails.logger.info "Stream: #{@playlist.name} - playing file #{path}"

      file, size = File.open(path, 'rb'), File.size(path)
      @next = false

      while !@next && data = file.read(BLOCKSIZE)
        Rails.logger.info "Stream: #{@playlist.name} sending block...:#{connected?.inspect}"
        self.send data
        Rails.logger.info "Stream: #{@playlist.name} - Block sent: #{file.pos.to_f / size} #{connected?.inspect}"

        # Do not call self.sync! This will cause the entire process to freeze
        # and do weird things (freeze all other running threads). Instead
        # just get the delay and sleep with ruby
        d = self.delay.to_f

        if d > 0
          Rails.logger.info "Stream: #{@playlist.name} - sleeping #{d}ms"
          # Different sizes for different songs will cause sleeping for
          # different periods of time. Make sure that the icecast server won't
          # time out if we sleep for too long
          sleep d / 1000
        else
          Rails.logger.info "Stream: #{@playlist.name} - negative delay..."
        end
      end

      Rails.logger.info "Stream: #{@playlist.name} - done playing file #{path}"
    ensure
      file.close if file
    end

    def random_song playlist
      if playlist.pool.songs.count > 0
        scope = playlist.pool.songs.scoped
      else
        scope = Song.scoped
      end

      scope.offset(rand(scope.count)).first
    end

  end
end
