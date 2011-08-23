class SongUploader < CarrierWave::Uploader::Base

  storage :file
  process :encode_to_mp3

  def artist
    (@tags ||= tags)[1]
  end

  def title
    (@tags ||= tags)[0]
  end

  def album
    (@tags ||= tags)[2]
  end

  def extension_white_list
    %w(mp3 flac m4a)
  end

  def process! *args
    # Only process the model if we're persisted. We don't want to do processing
    # if there's a validation error with the model. Only afterwards do we
    # go through all that hard work.
    super if model.persisted?
  end

  def encode_to_mp3
    if current_path =~ /flac$/i
      convert_extension 'flac', title, artist, album, 'flac -cd'
    elsif current_path =~ /m4a$/i
      convert_extension 'm4a', title, artist, album, 'faad -w'
    elsif current_path =~ /mp3$/i
      # Convert specially here because otherwise we'd be converting in-place.
      i = Mp3Info.open(current_path)
      if i.bitrate != bitrate || i.samplerate != samplerate
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
    else
      raise CarrierWave::IntegrityError,
          "Doesn't support #{File.basename(current_path)}"
    end
  end

  protected

  def tags
    if current_path =~ /flac$/
      tags = FlacInfo.new(current_path).tags
      [tags['TITLE'], tags['ARTIST'], tags['ALBUM']]
    elsif current_path =~ /mp3$/
      info = Mp3Info.new(current_path)
      [info.tag['title'], info.tag['artist'], info.tag['album']]
    elsif current_path =~ /m4a$/
      tags = MP4Info.open(current_path)
      [tags.NAM, tags.ART, tags.ALB]
    else
      [nil, nil, nil]
    end
  end

  # Make sure that all songs are the same bitrate and are sampled at the same
  # rate. The bitrate is high so we'll have large files, but hopefully not much
  # loss of quality. The sample rate needs to be the same for the icecast server
  # to agree with playing songs.
  #
  # Apparently, shout doesn't like streams with different bit rates. This
  # causes some songs to go silent while others play. Because everything
  # sounds better in 320, just convert all songs up to 320 and we won't lose
  # anything from those mp3's in 128 and we won't lose as much from flac's
  # and m4a/mp4's
  def lame_opts
    "--quiet -h -b #{bitrate} --resample #{samplerate}"
  end

  def bitrate; 320; end
  def samplerate; 48000; end

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

    # Change the @filename variable for carrierwave to make sure we preserve
    # the right file.
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
