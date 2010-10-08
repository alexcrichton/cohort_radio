require 'drb'

class Radio
  class ProxyDaemon < Radio::Daemon

    def daemon_name
      'radio'
    end

    def run
      Rails.logger = Logger.new $stdout
      ActiveRecord::Base.connection.reconnect!

      radio = Radio.new

      DRb.start_service 'druby://127.0.0.1:8083', radio
      Rails.logger.info 'Connecting radio...'

      DRb.thread.join
    end

  end
end
