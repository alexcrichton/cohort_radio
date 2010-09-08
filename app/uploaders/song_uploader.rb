class SongUploader < CarrierWave::Uploader::Base
  include CarrierWave::Compatibility::Paperclip

  storage :file

  process :encode_to_mp3

  def paperclip_path
    ':rails_root/private/songs/audios/:id/:basename.:extension'
  end

  def extension_white_list
    %w(mp3 flac)
  end

  def encode_to_mp3
  end

end
