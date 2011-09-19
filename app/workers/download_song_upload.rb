require 'tmpdir'

class DownloadSongUpload

  @queue = :songs

  def self.perform url
    uri = URI.parse(url)
    dir = Dir.mktmpdir
    file = File.join dir, File.basename(uri.path)
    File.open(file, 'wb') { |f| f << Net::HTTP.get(uri) }
    Resque.enqueue ConvertSong, file
    uri.query = 'delete=true'
    Net::HTTP.get(uri)
  end

end
