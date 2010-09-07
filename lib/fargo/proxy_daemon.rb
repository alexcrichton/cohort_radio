require 'drb'

module Fargo
  class ProxyDaemon < Radio::Daemon
    
    @@enqueue_lock = Mutex.new
    
    def run
      Fargo.logger = Rails.logger
      ActiveRecord::Base.connection.reconnect!

      client = Fargo::Client.new

      # If a download just finished, we're going to want to convert the
      # file to put it in our database. Do this in separate threads
      # to not hang things up.
      client.subscribe { |type, hash|
        if type == :download_finished
          spawn_thread {
            Fargo.logger.info "Converting: #{hash.inspect}"
            convert_song hash[:file] 
            thread_complete
          }
        end
      }

      trap('EXIT') { Fargo.logger.info 'Exiting...'; proxy.disconnect }

      DRb.start_service 'drbunix:///tmp/fargo.sock', client
      DRb.thread.join
    end
        
    def convert_song file
      # Only enqueue one thing at a time. There was problems running into the
      # connection pool running low as a result of many downloads finishing
      # simultaneously. A pool of 10 ran out very quickly.
      @@enqueue_lock.synchronize { 
        Fargo.logger.info "Queueing create song job for: #{file.inspect}"
        ActiveRecord::Base.verify_active_connections!
        Delayed::Job.enqueue CreateSongJob.new(file)
      }
    end
    
    def daemon_name
      'fargo'
    end
        
  end
end
