class ScrobbleAlbum

  @queue = :scrobble

  API_URL = 'http://ws.audioscrobbler.com/1.0/album/%s/%s/info.xml'

  def self.perform artist_id, id
    artist = Artist.find(artist_id)
    album  = artist.albums.find(id)
    url = API_URL % [CGI.escape(artist.name), CGI.escape(album.name)]
    xml = LibXML::XML::Document.file url
    album.cover_url = xml.find_first('//coverart/large').content
    album.save!
  end

end
