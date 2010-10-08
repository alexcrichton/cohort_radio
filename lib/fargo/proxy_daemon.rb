require 'drb'

module Fargo
  class ProxyDaemon < Radio::Daemon

    @@enqueue_lock = Mutex.new

    def run
      Fargo.logger = Rails.logger
      ActiveRecord::Base.connection.reconnect!

      client = Fargo::Client.new
      client.config.download_dir = Rails.root.join('tmp', 'fargo').to_s

      # If a download just finished, we're going to want to convert the
      # file to put it in our database.
      client.channel.subscribe do |type, hash|
        if type == :download_finished
          Fargo.logger.info "Converting: #{hash.inspect}"
          convert_song hash[:file]
        end
      end

      trap('EXIT') { Fargo.logger.info 'Exiting...'; client.disconnect }

      DRb.start_service 'druby://127.0.0.1:8082', client
      EventMachine.run{ client.connect }
    end

    def convert_song file
      # Only enqueue one thing at a time. There was problems running into the
      # connection pool running low as a result of many downloads finishing
      # simultaneously. A pool of 10 ran out very quickly.
      @@enqueue_lock.synchronize {
        Fargo.logger.info "Queueing create song job for: #{file.inspect}"
        ActiveRecord::Base.verify_active_connections!
        CreateSongJob.new(file).perform
      }
    end

    def daemon_name
      'fargo'
    end

  end
end
