class DownloadSongJob < Struct.new(:nick, :file)
  
  include Radio::FargoHelper
  
  def perform
    @thread = Thread.current
    @file = nil
  
    # Wait for 5 seconds for the download to start
    @stop_thread = Thread.start {
      sleep 5
      @message = 'Download didn\'t start within 5 seconds!'
      @thread.wakeup
    }
    
    block = lambda { |type, map| 
      if map[:nick] == nick && map[:remote_file] == file
        if type == :download_finished
          @file = map[:file]
          @thread.wakeup
        elsif type == :download_failed
          @message = "Download failed received #{map.inspect}"
          @thread.wakeup
        elsif type == :download_progress
          @stop_thread.exit if @stop_thread.alive? # the download has started, don't do this
        end
      end
    }
    
    fargo.subscribe &block
    fargo.download nick, file
    
    sleep # wait for the download to finish
    fargo.unsubscribe &block

    # create the song and delete the downloaded file (it's copied by paperclip)
    raise @message unless @message.nil?

    Song.create! :audio => File.new(@file)
    File.delete @file
  rescue => e
    Exceptional.handle e
    raise e
  end
  
end