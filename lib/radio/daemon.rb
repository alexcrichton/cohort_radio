class Radio
  class Daemon
    
    include Radio::Proxy::Utils
    
    def initialize(args)
      @files_to_reopen = []

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"
      # 
      #   opts.on('-h', '--help', 'Show this message') do
      #     puts opts
      #     exit 1
      #   end
      #   opts.on('-e', '--environment=NAME', 'Specifies the environment to run this delayed jobs under (test/development/production).') do |e|
      #     STDERR.puts "The -e/--environment option has been deprecated and has no effect. Use RAILS_ENV and see http://github.com/collectiveidea/delayed_job/issues/#issue/7"
      #   end
        opts.on('-p', '--port N', 'Port to run on.') do |port|
          @port = port.to_i
        end
      #   opts.on('--max-priority N', 'Maximum priority of jobs to run.') do |n|
      #     @options[:max_priority] = n
      #   end
      #   opts.on('-n', '--number_of_workers=workers', "Number of unique workers to spawn") do |worker_count|
      #     @worker_count = worker_count.to_i rescue 1
      #   end
      end
      @args = opts.parse!(args)
    end
    
    def daemonize
      ObjectSpace.each_object(File) do |file|
        @files_to_reopen << file unless file.closed?
      end
      
      Daemons.run_proc(daemon_name, :dir => "#{::Rails.root}/tmp/pids", :dir_mode => :normal, :ARGV => @args) do |*args|  
        Dir.chdir Rails.root
        
        # re-open file handles
        @files_to_reopen.each do |file|
          begin
            file.reopen File.join(Rails.root, 'log', "#{daemon_name}.log"), 'w+'
            file.sync = true
          rescue ::Exception => e
            Exceptional.handle e
          end
        end
        # needed to log for some reason in production mode
        Rails.logger.auto_flushing = true
        
        begin
          run
        rescue => e
          Rails.logger.fatal e
          Exceptional.handle e
          STDERR.puts e.message
          exit 1
        end
      end
    end      
    
    def run
      raise "Not implemented yet!"
    end
    
    def daemon_name
      raise "Not implemented yet!"
    end
    
  end
end
