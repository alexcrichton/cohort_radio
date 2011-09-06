class WriteMetadata

  @queue = :songs

  def self.perform id
    song = Song.find id
    info = Mp3Info.open song.audio.path, :encoding => 'utf-8'
    info.tag['artist'] = song.artist_name unless song.artist_name == 'unknown'
    info.tag['album']  = song.album_name  unless song.album_name  == 'unknown'
    info.tag['title']  = song.title
    info.close
  end

end
