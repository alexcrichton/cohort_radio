class CreateSongJob < Struct.new(:file)
  
  def perform
    raise "File didn't download!" unless File.exists?(file)
    Song.create_song! file
    File.delete file
  rescue => e
    Exceptional.handle e
    raise e
  end
  
end