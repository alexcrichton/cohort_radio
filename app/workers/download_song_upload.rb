require 'tempfile'

class DownloadSongUpload

  @queue = :songs

  def self.perform url
    file = Tempfile.new 'download'
    file.binmode
    uri = URI.parse(url)
    file << Net::HTTP.get(uri)
    file.close(false)
    Resque.enqueue ConvertSong, file.path
    uri.query = 'delete=true'
    Net::HTTP.get(uri)
  end

end
