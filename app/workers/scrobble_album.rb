class ScrobbleAlbum

  @queue = :songs

  API_URL = 'http://ws.audioscrobbler.com/1.0/album/%s/%s/info.xml'

  def self.perform id
    album = Album.find(id)
    url = API_URL % [CGI.escape(album.artist.name), CGI.escape(album.name)]
    xml = LibXML::XML::Document.file url
    album.cover_url = xml.find_first('//coverart/large').content
    album.save!
  end

end
