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
    completion = nil
    block = lambda do |args|
      type, message = args
      next unless message[:download] == @download

      if type == :download_started
        set_status "Downloading of '#{options['file']}'"
      elsif type == :download_progress
        EM.schedule { at message[:percent], 1 }
      elsif type == :download_finished
        completion = message
        finished.decrement
      end
    end

    # We can't subscribe outside of the event-loop because otherwise we're
    # possibly subjected to a few race conditions.
    EventMachine.schedule { @sid = @@client.channel.subscribe block }
    finished.wait # Block until the download is finished
    EventMachine.schedule { @@client.channel.unsubscribe @sid }

    raise completion[:last_error] if completion[:failed]

    if completion[:file] =~ /(m4a|mp3|flac|wav)$/i
      Resque.enqueue ConvertSong, completion[:file]
      completed "#{completion[:file]} queued for processing"
    elsif ENV['FARGO_DESTINATION'] &&
          File.writable?(ENV['FARGO_DESTINATION'])
      i = ''
      begin
        destination = File.join ENV['FARGO_DESTINATION'],
                                i + File.basename(completion[:file])
        i += 'x'
      end while File.exists?(destination)

      FileUtils.mv completion[:file], destination
      completed "#{completion[:file]} moved to #{destination}"
    else
      completed "Download finished into #{completion[:file]}"
    end
  end

end
