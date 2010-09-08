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
    if current_path =~ /flac$/
      filename = File.basename(current_path, '.flac') + '.mp3'
      f = File.dirname(current_path) + '/' + filename
      system "flac -cd #{current_path} | lame -h -b 320 - #{f}"

      tags = FlacInfo.new(current_path).tags
      info = Mp3Info.new(f)
      info.tag['artist'] = tags['ARTIST']
      info.tag['album']  = tags['ALBUM']
      info.tag['title']  = tags['TITLE']
      info.close

      FileUtils.mv f, current_path

      @filename = filename
    elsif current_path =~ /mp3$/
      # Nothing to do here...
    else
      raise CarrierWave::IntegrityError,
          "Doesn't support #{File.basename(current_path)}"
    end
  end

end
