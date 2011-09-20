class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = 'Access denied.'
    store_location unless current_user

    redirect_to current_user ? playlists_path : new_user_session_path
  end

  before_filter :prepare_for_mobile

  private

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == '1'
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
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
