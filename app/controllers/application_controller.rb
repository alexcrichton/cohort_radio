# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # nil for AJAX
  layout Proc.new { |controller| controller.request.xhr? ? nil : 'application' }

  # Authlogic stuff
  helper_method :current_user_session, :current_user

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = 'Access denied.'
    store_location unless current_user

    redirect_to current_user ? playlists_path : login_url
  end

  private

  def require_fargo_connected
    return true if fargo_connected?

    flash[:error] = "Fargo is not connected!"
    redirect_to playlists_path
  end

  def require_radio_running
    return true if radio_running?

    flash[:error] = "Radio is not running!"
    redirect_to playlists_path
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def current_ability
    @current_ability ||= Ability.new current_user, @parent
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default default, *options
    redirect_to session[:return_to] || request.referrer || default, *options

    session[:return_to] = nil
  end

end
