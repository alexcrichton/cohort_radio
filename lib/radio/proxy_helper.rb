require 'drb'

class Radio
  module ProxyHelper

    def radio
      @radio_client ||= DRbObject.new_with_uri('druby://127.0.0.1:8083')
    end

    def radio_running?
      !(radio.connected? =~ /error/i)
    rescue DRb::DRbConnError, Errno::ENOENT
      false
    end

    def radio_connected?
      radio_running? && radio.connected?
    end

  end
end

ActionController::Base.class_eval { include Radio::ProxyHelper }
ActionView::Base.class_eval       { include Radio::ProxyHelper }
