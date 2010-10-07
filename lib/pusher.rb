module Pusher
  def push data, options = {}
    @channel ||= DRbObject.new_with_uri 'druby://localhost:8081'

    options[:except] ||= [current_user.id]
    @channel << options.merge(:data => data.to_json)
  rescue DRb::DRbConnError
  end
end

ActionController::Base.send :include, Pusher
