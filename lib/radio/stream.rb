class Radio
  class Stream < Shout

    BLOCKSIZE = (1 << 16).freeze

    attr_accessor :radio

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
      @playlist.playing = true
      @playlist.current_song = nil
      EventMachine.defer lambda{ @playlist.save! }, lambda{ |_|
        Pusher['playlist-' + @playlist.slug].trigger_async('connected', {})
        play_song
      }

      Radio.logger.debug "Stream: #{@playlist.name} connected"
      true
    end

    def disconnect
      Radio.logger.info "Stream: #{@playlist.name} disconnecting"

      @next = true
      @playlist.playing = false
      @playlist.current_song = nil
      EventMachine.defer { @playlist.save! }
      Pusher['playlist-' + @playlist.slug].trigger_async('disconnected', {})
    end

    def next
      @next = true
    end

    def next_song &block
      EventMachine.defer proc {
        # Get a fresh copy of the playlist because the queue items are embedded
        queue_item = @playlist.reload.queue_items.first
        song       = queue_item.nil? ? @playlist.random_song : queue_item.song
        [queue_item, song]
      }, proc { |queue_item, song|
        m = ShoutMetadata.new
        m.add 'filename', song.audio.path
        title  = song.audio.title
        artist = song.audio.artist
        album  = song.audio.album

        string = title || 'unknown'
        string << ' ('
        string << artist unless artist.blank?
        if album.present?
          string << ' - '
          string << album
        end
        string << ')'

        m.add 'song',   string
        m.add 'artist', artist unless artist.blank?
        m.add 'album',  album  unless album.blank?
        m.add 'genre', 'awesome'

        block.call song, m, queue_item
      }
    end

    def play_song
      next_song do |song, metadata, queue_item|
        @song = song
        @queue_item = queue_item

        @playlist.current_song = @song.title
        EventMachine.defer lambda{ @playlist.save! }, lambda{ |_| stream_song }

        self.metadata = metadata

        Pusher['playlist-' + @playlist.slug].trigger_async('playing',
          :song => song.title
        )

        Radio.logger.info "Stream: #{@playlist.name} => #{song.audio.path}"
        @file = File.open(song.audio.path, 'rb')
        @size = File.size(song.audio.path)
        @next = false
      end
    end

    def stream_song
      return finish_stream if @next || (data = @file.read(BLOCKSIZE)).nil?

      Radio.logger.debug "Stream: #{@playlist.name} sending block..."

      EventMachine.defer proc {
        begin
          self.send data
          pct = '%.2f%%' % [@file.pos.to_f / @size * 100]
          Radio.logger.debug "Stream: #{@playlist.name} #{pct}"
          self.delay.to_f
        rescue ShoutError => e
          Radio.logger.warn("ShoutError!!!: #{e.message}")
          e
        end
      }, proc { |delay_or_exception|
        if delay_or_exception.is_a?(ShoutError)
          finish_stream delay_or_exception
        else
          # If the delay is negative, the timer will immediately fire
          EventMachine.add_timer(delay_or_exception / 1000.0){ stream_song }
        end
      }
    end

    def finish_stream err = nil
      Radio.logger.debug "Stream: #{@playlist.name} - done - #{@file.path}"
      @file.close

      if err.nil? && @playlist.playing
        EventMachine.next_tick { play_song }
      else
        begin
          shout_disconnect
        rescue ShoutError
          disconnect # Performs necessary metadata updates
          return # Don't destroy our queue item
        end
      end

      @song.inc :play_count, 1
      if @queue_item
        @queue_item.destroy
        Pusher['playlist-' + @playlist.slug].trigger_async('queue_removed',
          :queue_id => @queue_item.id
        )
      end

      @song = @queue_item = @file = nil
    end

  end
end
