require 'net/http'

class ScrobbleAlbum

  @queue = :songs

  API_URL = 'http://ws.audioscrobbler.com/1.0/album/%s/%s/info.xml'

  def self.perform id
    album = Album.find(id)
    url = API_URL % [CGI.escape(album.artist.name), CGI.escape(album.name)]
    uri = URI.parse url
    res = Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path) }

    if res.is_a?(Net::HTTPSuccess)
      doc = LibXML::XML::Document.string res.body
      album.cover_url = doc.find_first('//coverart/large').content
      album.save!
    end
  end

end
