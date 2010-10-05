class Radio
  class Daemon

    def initialize(args)
      @files_to_reopen = []

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"
      end
      @args = opts.parse!(args)
    end

    def daemonize
      ObjectSpace.each_object(File) do |file|
        @files_to_reopen << file unless file.closed?
      end

      @files_to_reopen += [$stdout, $stderr]

      Daemons.run_proc(daemon_name, :dir => "#{::Rails.root}/tmp/pids", :dir_mode => :normal, :ARGV => @args) do |*args|
        Dir.chdir Rails.root

        # re-open file handles
        @files_to_reopen.each do |file|
          file.reopen File.join(Rails.root, 'log', "#{daemon_name}.log"), 'a+'
          file.sync = true
        end
        # needed to log for some reason in production mode
        Rails.logger.auto_flushing = true

        begin
          run
        rescue => e
          Rails.logger.fatal e
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
