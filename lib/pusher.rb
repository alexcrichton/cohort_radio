require 'drb'

module Pusher
  def push data, options = {}
    @channel ||= DRbObject.new_with_uri 'druby://127.0.0.1:8081'

    options[:except] ||= [current_user.id]
    push = options.merge(:data => data.to_json)
    @channel << push
    Rails.logger.debug "Pushed data: #{push.inspect}"
  rescue DRb::DRbConnError
  end
end

ActionController::Base.send :include, Pusher
