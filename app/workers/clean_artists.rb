class CleanArtists

  @queue = :cleaner

  def self.perform
    Album.all.each do |album|
      album.destroy if album.songs.size == 0
    end

    Artist.all.each do |artist|
      artist.destroy if artist.songs.size == 0 && artist.albums.size == 0
    end

    if ENV['FARGO_LINK_DEST']
      path = Pathname.new ENV['FARGO_LINK_DEST']
      Song.all.each do |song|
        song_path = path.join(song.artist_name, song.album_name,
                              song.title + '.mp3')
        song_path.dirname.mkpath
        FileUtils.ln_sf song.audio.path, song_path.to_s
      end
    end

    CarrierWave.clean_cached_files!
  end

end
