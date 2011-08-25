class ConvertSong

  @queue = :convert_song

  def self.perform file
    raise "File didn't download!" unless File.exists?(file)
    io = File.open(file)
    begin
      s = Song.new :audio => io
      File.delete s.audio.path if s.audio_processing_error
      s.save!
      File.delete file
    ensure
      io.close
    end
  end

end
