class WriteMetadata

  @queue = :songs

  def self.perform id
    song = Song.find id
    info = Mp3Info.new song.audio.path
    info.tag['artist'] = song.artist.name unless song.artist.name == 'unknown'
    info.tag['album']  = song.album.name  unless song.album.name  == 'unknown'
    info.tag['title']  = song.title
    info.close
  end

end
