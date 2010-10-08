module Radio
  class Daemon

    def self.run
      Radio.setup_logging 'radio.log'

      ActiveRecord::Base.connection.reconnect!

      radio = Radio::Giraffe.new

      DRb.start_service 'druby://127.0.0.1:8083', radio
      Rails.logger.info 'Connecting radio...'

      radio.connect

      DRb.thread.join
    end

  end
end
