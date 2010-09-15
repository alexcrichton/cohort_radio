class SongUploader < CarrierWave::Uploader::Base

  include CarrierWave::Compatibility::Paperclip

  storage :file

  process :encode_to_mp3

  def paperclip_path
    ':rails_root/private/songs/audios/:id/:basename.:extension'
  end

  def extension_white_list
    %w(mp3 flac m4a)
  end

  def encode_to_mp3
    if current_path =~ /flac$/
      tags = FlacInfo.new(current_path).tags
      convert_extension 'flac', tags['TITLE'], tags['ARTIST'], tags['ALBUM'],
        'flac -cd'
    elsif current_path =~ /mp3$/
      # Nothing to do here...
    elsif current_path =~ /m4a$/
      tags = MP4Info.open(current_path)
      convert_extension 'm4a', tags.NAM, tags.ART, tags.ALB, 'faad -w'
    else
      raise CarrierWave::IntegrityError,
          "Doesn't support #{File.basename(current_path)}"
    end
  end

  protected

  def convert_extension ext, title, artist, album, command
    filename = File.basename(current_path, '.' + ext) + '.mp3'
    f = File.dirname(current_path) + '/' + filename

    system "#{command} #{current_path} | lame -h -b 320 - #{f}"
    if $?.exitstatus > 0
      raise CarrierWave::IntegrityError,
          "Couldn't process #{File.basename(current_path)}"
    end

    info = Mp3Info.new(f)
    info.tag['artist'] = artist
    info.tag['album']  = album
    info.tag['title']  = title
    info.close

    FileUtils.mv f, current_path

    @filename = filename
  end
end
