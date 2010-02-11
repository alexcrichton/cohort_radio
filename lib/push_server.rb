require 'eventmachine'
require 'evma_httpserver'
require 'logger'
require 'socket'
require 'cgi'
require 'base64'
require 'active_support'
require 'action_controller'

require File.dirname(__FILE__) + '/../config/initializers/session_store'

class PushServer < EventMachine::Connection
  include EventMachine::HttpServer
  include EventMachine::Deferrable
  
  @@things = []
  cattr_accessor :logger
  PushServer.logger = Logger.new STDOUT
  attr_reader :resp
  
  def process_http_request
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    @cookies = CGI::Cookie.parse(@http_cookie)

    callback { @resp.status = 200; @resp.send_response }
    errback { @resp.content = "timeout"; succeed}

    @resp = EventMachine::DelegatedHttpResponse.new(self)

    if data = server?
      PushServer.push data
      @resp.content = 'Done.'
      succeed
    elsif data = client?
      PushServer.logger.info "Client connection: #{ip}"
      timeout 50
      @@things << self
      @creds = data
    else
      PushServer.logger.warn "Erroneous connection: #{ip}"
      @resp.content = "Nice try."
      succeed
    end

  end

  def unbind
    @@things.delete(self)
    super
  end

  def accept?(ids)
    return ids.nil? || ids.size == 0 || ids.include?(@creds[:user_credentials_id].to_i)
  end

  def self.push(data)
    logger.info "Pushing: #{data}"
    @@things.reject{ |t| !t.accept?(data[:ids]) }.each do |t|
      t.resp.content = data[:html]
      t.succeed
    end
  end

  def self.secret
    ActionController::Base.session_options[:secret]
  end

  protected 
  # TODO: authenticate with the secret/digest here but I couldn't replicate
  # the authentication algorithm?!
  def client?
    key = ActionController::Base.session_options[:key]
    return false if @cookies[key].nil? || @cookies[key][0].nil? || @http_request_method != 'GET'
    data, digest = @cookies[key][0].split('--')
    session = Marshal.load(Base64.decode64(data))
    session.symbolize_keys! if session
    return session if session && session[:user_credentials] && session[:user_credentials_id] && session[:session_id]
    false
  end

  def server?
    return false if @http_request_method != 'POST'
    mv = ActiveSupport::MessageVerifier.new(PushServer.secret)
    mv.verify CGI.parse(@http_post_content)['body'][0]
    rescue ActiveSupport::MessageVerifier::InvalidSignature
    false
  end

end
