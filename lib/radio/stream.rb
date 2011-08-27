class Radio
  class Stream < Shout

    BLOCKSIZE = (1 << 16).freeze

    attr_accessor :radio
    attr_reader :current_song

    alias :shout_disconnect :disconnect

    def initialize radio, playlist_id
      super()
      @radio    = radio
      @playlist = Playlist.find_by_slug! playlist_id
    end

    def connect
      return if connected?

      Radio.logger.info puts "Stream: #{@playlist.name} connecting"

      self.host         = @radio.config.host
      self.port         = @radio.config.port
      self.user         = @radio.config.user
      self.pass         = @radio.config.password
      self.mount        = @playlist.ice_mount_point
      self.name         = @playlist.ice_name
      self.description  = @playlist.description
      self.format       = Shout::MP3

      super

      # Schedule the actual playing of the song
      @playing = true
      EventMachine.next_tick{ play_song }

      Rails.logger.debug "Stream: #{@playlist.name} connected"
      true
    end

    def disconnect
      Rails.logger.info "Stream: #{@playlist.name} disconnecting"

      if @playing
        Rails.logger.debug "Stream: #{@playlist.name} joining with the song thread"
        @playing = false
      end

      @current_song = nil
    end

    def next
      @next = true
    end

    def next_song &block
      EventMachine.defer proc {
        # Get a fresh copy of the playlist because the queue items are embedded
        queue_item = @playlist.reload.queue_items.first
        song       = queue_item.nil? ? random_song : queue_item.song
        [queue_item, song]
      }, proc { |queue_item, song|
        m = ShoutMetadata.new
        m.add 'filename', song.audio.path
        info   = Mp3Info.new(song.audio.path)
        title  = info['title']
        artist = info['artist'] || ''
        album  = info['album']  || ''

        string = title
        string << ' ('
        string << artist unless artist == ''
        if album != ''
          string << ' - '
          string << album
        end
        string << ')'

        m.add 'song',   string
        m.add 'artist', artist unless artist == ''
        m.add 'album',  album  unless album  == ''
        m.add 'bitrate', info.bitrate.to_s
        m.add 'genre', 'awesome'

        block.call song, m, queue_item
      }
    end

    def random_song
      if @playlist.pool.songs.count > 0
        scope = @playlist.pool.songs
      else
        scope = Song.scoped
      end

      scope.offset(rand(scope.count)).first
    end

    def play_song
      next_song do |song, metadata, queue_item|
        @song = song
        @queue_item = queue_item

        @current_song = song.title
        self.metadata = metadata

        Pusher['playlist-' + @playlist.slug].async_trigger('playing',
          :playlist_id => @playlist.slug, :song => song.title
        )

        Rails.logger.info "Stream: #{@playlist.name} - playing file #{path}"
        @file = File.open(song.audio.path, 'rb')
        @size = File.size(song.audio.path)
        @next = false
        stream_song
      end
    end

    def stream_song
      return finish_stream if @next || (data = file.read(BLOCKSIZE)).nil?

      Radio.logger.debug "Stream: #{@playlist.name} sending block..."

      EventMachine.defer proc {
        self.send data
        Radio.logger.debug "Stream: #{@playlist.name}: #{file.pos.to_f / size}"
        self.delay.to_f
      }, proc { |delay|
        # If the delay is negative, the timer will immediately fire
        EventMachine.add_timer(delay){ stream_song }
      }
    end

    def finish_stream
      Rails.logger.debug "Stream: #{@playlist.name} - done playing file #{path}"
      @file.close

      if @playing
        EventMachine.next_tick { play_song }
      else
        shout_disconnect
      end

      @song.increment! :play_count
      @queue_item.destroy

      Pusher['playlist-' + @playlist.slug].async_trigger('queue_removed',
        :playlist_id => @playlist.slug, :queue_id => @queue_item.title
      )
      @song = @queue_item = @file = nil
    end

  end
end
