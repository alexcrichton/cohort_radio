require 'drb'

module Pusher

  autoload :Daemon, 'pusher/daemon'

  def push data, options = {}
    @channel ||= DRbObject.new_with_uri 'druby://127.0.0.1:8081'

    if defined? current_user
      options[:except] ||= [current_user.id]
    else
      options[:except] ||= []
    end

    push = options.merge(:data => data.to_json)
    @channel << push
    Rails.logger.debug "Pushed data: #{push.inspect}"
  rescue DRb::DRbConnError
  end

end

ActionController::Base.send :include, Pusher
