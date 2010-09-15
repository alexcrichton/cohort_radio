class CreateSongJob < Struct.new(:file)

  def perform
    raise "File didn't download!" unless File.exists?(file)
    Song.create! :audio => File.open(file)
    File.delete file
  end

end