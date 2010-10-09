module Radio

  class Stream < Shout

    include Pusher

    BLOCKSIZE = (1 << 16).freeze

    @@tag_recoder = Iconv.new('utf-8', 'utf-8')

    attr_accessor :radio, :playlist_id
    attr_reader :current_song

    def initialize radio, playlist_id
      super()
      @radio       = radio
      @playlist_id = playlist_id
    end

    def connect
      return if connected?

      @playlist = Playlist.find(playlist_id)
      Rails.logger.info "Stream: #{@playlist.name} connecting"

      self.host         = @radio.config.host
      self.port         = @radio.config.port
      self.user         = @radio.config.user
      self.pass         = @radio.config.password
      self.mount        = @playlist.ice_mount_point
      self.name         = @playlist.ice_name
      self.description  = @playlist.description if @playlist.description
      self.format       = Shout::MP3

      super

      @loop = true

      # play songs in a different thread
      @song_thread = Thread.start { while @loop; play_song; end }

      Rails.logger.info "Stream: #{@playlist.name} connected"
      true
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
      playlist   = Playlist.find playlist_id
      queue_item = playlist.queue_items.first
      song       = queue_item.nil? ? random_song(playlist) : queue_item.song

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
      m.add 'bitrate', Mp3Info.new(song.audio.path).bitrate.to_s
      m.add 'genre', 'awesome'

      [song, m, queue_item]
    end

    def play_song
      song, metadata, queue_item = next_song

      @current_song = song.title

      self.metadata = metadata
      push :type => 'playlist.playing', :playlist_id => @playlist.to_param,
        :song => song.title

      stream_song song.audio.path

      update_song queue_item
    end

    def update_song queue_item
      return if queue_item.nil?
      ActiveRecord::Base.verify_active_connections!

      queue_item.song.increment! :play_count
      queue_item.destroy

      push :type => 'playlist.queue_removed',
        :playlist_id => @playlist.to_param, :queue_id => queue_item.id
    end

    def stream_song path
      Rails.logger.info "Stream: #{@playlist.name} - playing file #{path}"

      file, size = File.open(path, 'rb'), File.size(path)
      @next = false

      while !@next && data = file.read(BLOCKSIZE)
        Rails.logger.debug "Stream: #{@playlist.name} sending block...:#{connected?.inspect}"
        self.send data
        Rails.logger.debug "Stream: #{@playlist.name} - Block sent: #{file.pos.to_f / size} #{connected?.inspect}"

        # Do not call self.sync! This will cause the entire process to freeze
        # and do weird things (freeze all other running threads). Instead
        # just get the delay and sleep with ruby
        d = self.delay.to_f

        if d > 0
          Rails.logger.debug "Stream: #{@playlist.name} - sleeping #{d}ms"
          # Different sizes for different songs will cause sleeping for
          # different periods of time. Make sure that the icecast server won't
          # time out if we sleep for too long
          sleep d / 1000
        else
          Rails.logger.debug "Stream: #{@playlist.name} - negative delay..."
        end
      end

      Rails.logger.debug "Stream: #{@playlist.name} - done playing file #{path}"
    ensure
      file.close if file
    end

    def random_song playlist
      if playlist.pool.songs.count > 0
        scope = playlist.pool.songs
      else
        scope = Song.scoped
      end

      scope.offset(rand(scope.count)).first
    end

  end
end
