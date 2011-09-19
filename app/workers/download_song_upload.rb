require 'tmpdir'

class DownloadSongUpload

  @queue = :songs

  def self.perform filename
    grid = Mongo::GridFileSystem.new Mongoid.database
    dir  = Dir.mktmpdir
    file = File.join dir, filename
    File.open(file, 'wb') { |f| f << grid.open(filename, 'r') { |gf| gf.read } }
    Resque.enqueue ConvertSong, file
    grid.delete filename
  end

end
