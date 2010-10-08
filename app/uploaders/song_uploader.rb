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
      # Apparently, shout doesn't like streams with different bit rates. This
      # causes some songs to go silent while others play. Because everything
      # sounds better in 320, just convert all songs up to 320 and we won't lose
      # anything from those mp3's in 128 and we won't lose as much from flac's
      # and m4a/mp4's
      i = Mp3Info.open(current_path)
      if i.bitrate != 320 || i.samplerate != 48000
        info = Mp3Info.new(current_path)
        artist, album, title = info.tag['artist'], info.tag['album'], info.tag['title']
        info.close

        t = Tempfile.new('converting')
        safe_system "lame #{lame_opts} '#{current_path}' '#{t.path}'"
        safe_system "cp '#{t.path}' '#{current_path}'"

        # Lame doesn't preserve tags, re-write them now that we converted the
        # file
        info = Mp3Info.new(current_path)
        info.tag['artist'] = artist
        info.tag['album']  = album
        info.tag['title']  = title
        info.close
      end
    elsif current_path =~ /m4a$/
      tags = MP4Info.open(current_path)
      convert_extension 'm4a', tags.NAM, tags.ART, tags.ALB, 'faad -w'
    else
      raise CarrierWave::IntegrityError,
          "Doesn't support #{File.basename(current_path)}"
    end
  end

  protected

  def lame_opts
    '--quiet -h -b 320 --resample 48000'
  end

  def convert_extension ext, title, artist, album, command
    filename = File.basename(current_path, '.' + ext) + '.mp3'
    f = File.dirname(current_path) + '/' + filename

    safe_system "#{command} #{current_path} | lame #{lame_opts} - #{f}"

    info = Mp3Info.new(f)
    info.tag['artist'] = artist
    info.tag['album']  = album
    info.tag['title']  = title
    info.close

    FileUtils.mv f, current_path

    @filename = filename
  end

  def safe_system *args
    system *args

    if $?.exitstatus > 0
      raise CarrierWave::IntegrityError,
          "Couldn't process #{File.basename(current_path)}"
    end
  end
end
