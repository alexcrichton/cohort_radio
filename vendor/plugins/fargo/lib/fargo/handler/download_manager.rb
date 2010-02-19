module Fargo
  module Handler
    module DownloadManager
      
      def self.included(base)
        base.after_setup :initialize_queues
      end
      
      def download nick, file
        raise ConnectionException.new "Not connected yet!" unless options[:hub]
        raise ConnectionException.new "User #{nick} does not exist!" unless nicks.include? nick
        downloading[nick] << file
      end
      
      private
      def initialize_queues
        FileUtils.mkdir_p download_dir unless File.directory? download_dir
        
        @downloading = Hash.new{ |h, k| h[k] = [] }
        
        hub.subscribe { |type, hash| 
          if type == :connection && hash[:connection].is_a?(Fargo::Connection::Download)
          end
        }
      end
      
    end
  end
end
