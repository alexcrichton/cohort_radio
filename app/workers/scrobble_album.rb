class ScrobbleAlbum

  @queue = :scrobble

  def self.perform id
    album = Album.find id
    scrobble = Scrobbler::Album.new(album.artist.name, album.name,
                                    :include_info => true)
    album.cover_url = scrobble.image_large
    album.save!
  end

end
