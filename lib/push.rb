module Push

  module LongPolling

    @@verifier = ActiveSupport::MessageVerifier.new(ActionController::Base.session_options[:secret])

    def push(data)
      map = {}
      @data = data
      map[:html] = render_to_string(:template => 'push/data', :layout => false)
      map[:ids] = data[:ids] || []
      map[:ids] = map[:ids] - [current_user.id] unless data[:include_current] || current_user.nil?
      body = @@verifier.generate map

      Rails.logger.info "Pushing: #{body[0..50]}"
      
      Net::HTTP.post_form(URI.parse('http://127.0.0.1:8081/'), :body => body)
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error
    end
    
  end
  
end
