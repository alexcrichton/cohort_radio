# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # nil for AJAX
  layout proc { |controller| controller.request.xhr? ? nil : 'application' }

  before_filter :load_models

  # Authlogic stuff
  helper_method :current_user_session, :current_user
  
  rescue_from CanCan::AccessDenied do |exception|
    Exceptional.handle exception
    flash[:error] = 'Access denied.'
    store_location unless current_user
    redirect_to current_user ? playlists_url : login_url
  end

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def load_models
    @current = find_model params[:id]
    instance_variable_set "@#{controller_name.singularize}", @current

    regex = /(.+)_id/
    params.keys.each do |key|
      next unless regex.match(key)
      @parent = find_model params[key], regex.match(key)[1]
      instance_variable_set "@#{regex.match(key)[1]}", @parent
    end
  end
  
  def find_model id, name = controller_name
    return nil if id.blank?
    klass = name.to_s.classify.constantize
    if klass.include? Acts::Slug::InstanceMethods
      puts 'here'
      klass.find_by_slug id
    else
      klass.find(id.to_i)
    end
  # rescue NameError => e # id doesn't mean for this controller
  #   raise e
  end

end
