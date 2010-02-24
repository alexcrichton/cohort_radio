module Fargo
  module Supports
    module Downloads

      class Download < Struct.new(:nick, :file, :tth, :size)
        attr_accessor :percent, :status

        def file_list?
          file == 'files.xml.bz2'
        end
      end
      
      attr_reader :current_downloads, :finished_downloads, :queued_downloads, :failed_downloads,
                  :open_download_slots, :trying, :timed_out
      
      def self.included base
        base.after_setup :initialize_queues
      end
      
      def clear_failed_downloads
        failed_downloads.clear
      end
      
      def clear_finished_downloads
        finished_downloads.clear
      end

      def download nick, file, tth, size
        raise ConnectionException.new "Not connected yet!" unless options[:hub]
        raise ConnectionException.new "User #{nick} does not exist!" unless nicks.include? nick
        
        raise "TTH or size or file are nil!" if tth.nil? || size.nil? || file.nil?
        download = Download.new nick, file, tth, size
        download.percent = 0
        download.status = 'idle'
        if @timed_out.include? nick
          download.status = 'timeout'
          (@failed_downloads[nick] ||= []) << download
        else
          @downloading_lock.synchronize { 
            (@queued_downloads[nick] ||= []) << download
          }
          start_download
        end
      end
      
      def retry_download nick, file
        download = (@failed_downloads[nick] ||= []).detect{ |h| h.file == file }
        raise "Download of: #{nick}:#{file} isn't failed!" if download.nil?
        @failed_downloads[nick].delete download
        download download.nick, download.file, download.tth, download.size
      end
      
      def remove_download nick, file
        return_val = nil
        @downloading_lock.synchronize {
          @queued_downloads[nick] ||= []
          download = @queued_downloads[nick].detect{ |h| h.file == file }
          return_val = @queued_downloads[nick].delete download unless download.nil?
        }
        
        raise "The download: #{nick}:#{file} wasn't queued!" if return_val.nil?
        
        return_val
      end
      
      def lock_next_download! user, connection
        @downloading_lock.synchronize {
          return get_next_download_with_lock! user, connection
        }
      end
      
      def clear_timed_out
        @timed_out.clear
      end
      
      def try_again nick
        return false unless @timed_out.include? nick
        @timed_out.delete nick
        downloads = @failed_downloads[nick].dup
        @failed_downloads[nick].clear
        downloads.each { |d| download nick, d.file, d.tth, d.size }
        true
      end
      
      def start_download
        return false if open_download_slots == 0
        arr = nil
        @downloading_lock.synchronize {
          arr = @queued_downloads.to_a.detect{ |arr|
            nick, downloads = arr
            downloads.size > 0 && !@current_downloads.has_key?(nick) && !@trying.include?(nick) && !@timed_out.include?(nick) && has_slot?(nick)
          }

          return false if arr.nil? || arr.size == 0

          if connection_for arr[0]
            Fargo.logger.debug "Requesting previous connection downloads: #{arr[1].first}"
            download = get_next_download_with_lock! arr[0], connection_for(arr[0])
            connection_for(arr[0])[:download] = download
            connection_for(arr[0]).begin_download!
          else
            Fargo.logger.debug "Requesting connection with: #{arr[0]} for downloading"
            @trying << arr[0]
            connect_with arr[0]
          end
        }
        
      end
      
      private
      def get_next_download_with_lock! user, connection
        raise "No open slots!" if @open_download_slots <= 0
        
        raise "Already downloading from #{user}!" if @current_downloads[user]
        
        download = @queued_downloads[user].shift
        raise "Don't have anything in the queue for #{user}!" if download.nil?
        
        @current_downloads[user] = download 
        @trying.delete user

        Fargo.logger.debug "#{self}: Locking download: #{download}"
        
        block = Proc.new{ |type, map|
          if type == :download_progress
            download.percent = map[:percent]
          elsif type == :download_started
            download.status = 'downloading'
          elsif type == :download_finished
            download.percent = 1
            download.status = 'finished'
            download_finished! user, false
            connection.unsubscribe &block
          elsif type == :download_failed
            download.status = 'failed'
            download_finished! user, true
            connection.unsubscribe &block
          end
        }
        
        connection.subscribe &block
        
        download
      end
      
      def download_finished! user, failed
        download = nil
        @downloading_lock.synchronize{ 
          download = @current_downloads.delete user
          @open_download_slots += 1
        }
        
        if failed
          (@failed_downloads[user] ||= []) << download
        else
          (@finished_downloads[user] ||= []) << download
        end

        start_download
      end 
      
      def connection_failed_with! nick
        @trying.delete nick
        @timed_out << nick
        @downloading_lock.synchronize {
          @queued_downloads[nick].each{ |d| d.status = 'timeout' }
          @failed_downloads[nick] = (@failed_downloads[nick] || []) | @queued_downloads[nick]
          @queued_downloads[nick].clear
        }
        start_download
      end
      
      def initialize_queues
        self.download_slots = 4 if options[:download_slots].nil?
        
        FileUtils.mkdir_p download_dir unless File.directory? download_dir
        
        @downloading_lock = Mutex.new
        
        # Don't use Hash.new{} because this can't be dumped by Marshal
        @queued_downloads = {}
        @current_downloads = {}
        @failed_downloads = {}
        @finished_downloads = {}
        @trying = []
        @timed_out = []
        
        @open_download_slots = download_slots
        
        subscribe { |type, hash|
          if type == :connection_timeout
            connection_failed_with! hash[:nick] if @trying.include?(hash[:nick])
          end
        }
      end
      
    end
    
  
  end
end
