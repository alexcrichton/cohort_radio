module Radio
  extend ActiveSupport::Autoload

  autoload :Daemon
  autoload :Giraffe
  autoload :Stream
  autoload :ProxyHelper

  class << self
    delegate :config, :configure, :to => Radio::Giraffe
  end

  def self.setup_logging log_file
    if ARGV.include? '-d'
      to_reopen = []

      ObjectSpace.each_object(File) do |file|
        to_reopen << file unless file.closed?
      end

      to_reopen += [$stdout, $stderr]

      to_reopen.each do |file|
        file.reopen Rails.root.join('log', log_file), 'a+'
        file.sync = true
      end
    end

    Rails.logger = ActiveSupport::BufferedLogger.new $stdout
  end

end
