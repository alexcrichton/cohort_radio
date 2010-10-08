require 'drb'

module Fargo
  module ProxyHelper

    def fargo
      @fargo_client ||= DRbObject.new_with_uri('druby://localhost:8082')
    end

    def fargo_running?
      !(fargo.connected? =~ /error/i)
    rescue DRb::DRbConnError, Errno::ENOENT
      false
    end

    def fargo_connected?
      fargo_running? && fargo.connected?
    end

  end
end
