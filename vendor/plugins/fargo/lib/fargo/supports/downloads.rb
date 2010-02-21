module Fargo
  module Supports
    module Downloads
      
      attr_reader :current_downloads, :finished_downloads, :queued_downloads, :failed_downloads,
                  :open_download_slots
      
      def self.included(base)
        base.after_setup :initialize_queues
      end

      def download nick, file, tth, size
        raise ConnectionException.new "Not connected yet!" unless options[:hub]
        raise ConnectionException.new "User #{nick} does not exist!" unless nicks.include? nick
        
        raise "TTH or size or file are nil!" if tth.nil? || size.nil? || file.nil?
        download = Download.new nick, file, tth, size
        download.percent = 0
        download.status = 'idle'
        
        @downloading_lock.synchronize { 
          (@queued_downloads[nick] ||= []) << download
        }
        start_download
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
          raise "No open slots!" if @open_download_slots <= 0
        }
        download = nil
        @downloading_lock.synchronize { download = @queued_downloads[user].shift }
        raise "Don't have anything in the queue for #{user}!" if download.nil?
        
        @downloading_lock.synchronize { 
          @current_downloads[user] = download 
          @trying.delete user
        }
        
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
      
      private
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
      
      def start_download
        return false if open_download_slots == 0
        arr = nil
        @downloading_lock.synchronize {
          arr = @queued_downloads.reject{ |k, v| 
            v.size == 0 || @current_downloads.has_key?(k) || @trying.include?(k)
          }.shift
        }
        return false if arr.nil? || arr.size == 0
        
        if connection_for arr[0]
          Fargo.logger.debug "Requesting previous connection downloads: #{arr[1]}"
          download = lock_next_download! arr[0], connection_for(arr[0])
          connection_for(arr[0])[:download] = download
          connection_for(arr[0]).begin_download!
        else
          Fargo.logger.debug "Requesting connection with: #{arr[0]} for downloading"
          @trying << arr[0]
          connect_with arr[0]
        end
        
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
        
        @open_download_slots = download_slots
      end
      
    end
    
    class Download < Struct.new(:nick, :file, :tth, :size)
      attr_accessor :percent, :status
      
      def file_list?
        file == 'files.xml.bz2'
      end
    end
  
  end
end
