class SongUploader < CarrierWave::Uploader::Base

  include Shellwords

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
    %w(mp3 flac m4a wav)
  end

  def store_dir
    # Take the hash of the ID so we get some more entropy
    digest = Digest::MD5.hexdigest model.id.to_s
    Rails.root.join 'private', 'audio', digest[0..2], digest
  end

  def process! *args
    # Only process the model if we're persisted. We don't want to do processing
    # if there's a validation error with the model. Only afterwards do we
    # go through all that hard work.
    super if model.valid?
  end

  def encode_to_mp3
    infile  = current_path
    outfile = current_path + '.tmp'

    # Make sure that all songs are the same bitrate and are sampled at the same
    # rate. The bitrate is high so we'll have large files, but hopefully not
    # much loss of quality. The sample rate needs to be the same for the icecast
    # server to agree with playing songs.
    #
    # Apparently, shout doesn't like streams with different bit rates. This
    # causes some songs to go silent while others play. Because everything
    # sounds better in 320, just convert all songs up to 320 and we won't lose
    # anything from those mp3's in 128 and we won't lose as much from flac's
    # and m4a/mp4's
    safe_system "ffmpeg -i #{shellescape infile} -ar 48000 " \
                "-ab 320k -f mp3 #{shellescape outfile}"

    FileUtils.mv outfile, infile

    # Change the @filename variable for carrierwave to make sure we preserve
    # the right file.
    @filename = File.basename(infile, File.extname(infile)) + '.mp3'
  end

  protected

  def tags
    # Apparently ffmpeg prints out this information to stderr?
    info = `ffmpeg -i #{shellescape current_path} 2>&1`
    artist = info.match(/artist\s+: (.*)/i)
    title = info.match(/title\s+: (.*)/i)
    album = info.match(/album\s+: (.*)/i)

    [title ? title[1] : nil, artist ? artist[1] : nil, album ? album[1] : nil]
  end

  def safe_system *args
    system *args

    if $?.exitstatus > 0
      raise CarrierWave::ProcessingError,
          "Couldn't process #{File.basename(current_path)}. " \
          "Command failed: '#{args.join(' ')}'"
    end
  end

end
