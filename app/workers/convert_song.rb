class ConvertSong

  @queue = :convert_song

  def self.perform file
    raise "File didn't download!" unless File.exists?(file)
    io = File.open(file)
    begin
      Song.create! :audio => io
      File.delete file
    ensure
      io.close
    end
  end

end
