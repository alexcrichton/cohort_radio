class ConvertSong

  @queue = :songs

  def self.perform file
    raise "File didn't download!" unless File.exists?(file)
    io = File.open(file)
    begin
      s = Song.new :audio => io
      s.save!
      File.delete file
    ensure
      io.close
    end
  end

end
