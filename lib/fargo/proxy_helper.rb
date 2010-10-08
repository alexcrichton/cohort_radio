require 'drb'

module Fargo
  module ProxyHelper

    def fargo
      @fargo_client ||= DRbObject.new_with_uri('druby://127.0.0.1:8082')
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

ActionController::Base.class_eval { include Fargo::ProxyHelper }
ActionView::Base.class_eval       { include Fargo::ProxyHelper }
