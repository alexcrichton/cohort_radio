class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = 'Access denied.'
    store_location unless current_user

    redirect_to current_user ? playlists_path : new_user_session_path
  end

  private

  def require_fargo_connected
    # TODO: check if fargo connected
    return true if true # fargo_connected?

    flash[:error] = "Fargo is not connected!"
    redirect_to playlists_path
  end

  def current_user
    return @current_user if defined?(@current_user)
    token = session[:token] || cookies[:token]
    if token.nil?
      token = cookies.permanent.signed[:token] = session[:token] =
        SecureRandom.hex(16)
    end
    @current_user = User.where(:token => token).first ||
      User.create!(:token => token)
  end

  def current_ability
    @current_ability ||= Ability.new current_user, @parent
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default default, *options
    redirect_to session[:return_to] || request.referrer || default, *options

    session[:return_to] = nil
  end

end
