class CreateSongJob < Struct.new(:file)
  
  def perform
    Song.create! :audio => File.new(file)
    File.delete file
  rescue => e
    Exceptional.handle e
    raise e
  end
  
end