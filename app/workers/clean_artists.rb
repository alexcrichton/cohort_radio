class CleanArtists

  @queue = :cleaner

  def self.perform
    Album.all.each do |album|
      album.destroy if album.songs.size == 0
    end

    Artist.all.each do |artist|
      artist.destroy if artist.songs.size == 0 && artist.albums.size == 0
    end

    CarrierWave.clean_cached_files!
  end

end
