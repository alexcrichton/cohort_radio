require 'resque/job_with_status'

class FargoDownload < Resque::JobWithStatus

  @client = nil

  def self.queue; :downloads end
  def self.client= client; @@client = client end

  def perform
    set_status "Initiating download of '#{options['file']}'"
    finished = Fargo::BlockingCounter.new 1
    error = nil

    # We're running in a deferred thread pool, but the download operation
    # must happen on the reactor thread, so we must use EM.schedule here. We
    # also need to synchronize around waiting for the @download variable to
    # being filled in.
    EventMachine.schedule {
      begin
        @download = @@client.download options['nick'], options['file'],
                                      options['tth'], options['size']
      rescue => e
        error = e
      end
      finished.decrement
    }
    finished.wait
    raise e if error
    raise 'Could not start the download!' if @download.nil?

    finished = Fargo::BlockingCounter.new 1
    block = lambda do |args|
      type, message = args
      next unless message[:download] == @download

      if type == :download_started
        set_status "Downloading of '#{options['file']}'"
      elsif type == :download_progress
        EM.schedule { at message[:percent], 1 }
      elsif type == :download_finished
        if message[:failed]
          error = message[:last_error]
        else
          if message[:file] =~ /(m4a|mp3|flac)$/i
            Resque.enqueue ConvertSong, message[:file]
          end
          completed "Download finished into: #{message[:file]}"
        end
        finished.decrement
      end
    end

    # We can't subscribe outside of the event-loop because otherwise we're
    # possibly subjected to a few race conditions.
    EventMachine.schedule { @sid = @@client.channel.subscribe block }
    finished.wait # Block until the download is finished
    EventMachine.schedule { @@client.channel.unsubscribe @sid }
    raise error if error
  end

end
