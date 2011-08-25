class CleanArtists

  @queue = :cleaner

  def self.perform
    Artist.all.each do |artist|
      if artist.songs.size == 0
        artist.destroy
      else
        artist.albums.each do |album|
          album.destroy if album.songs.size == 0
        end
      end
    end

    CarrierWave.clean_cached_files!
  end

end
