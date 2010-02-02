# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation

  # nil for AJAX
  layout proc { |controller| controller.request.xhr? ? nil : 'application' }

  before_filter :load_models

  # Authlogic stuff
  helper_method :current_user_session, :current_user

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to login_path
      return false
    end
  end

  def require_admin
    unless current_user && current_user.admin
      store_location
      flash[:notice] = "You must be an administrator to access this page"
      redirect_to root_path
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_path
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def load_models
    begin
      @current = controller_name.classify.constantize.find(params[:id].to_i) if params[:id]
    rescue NameError # id doesn't mean for this controller
    rescue ActiveRecord::RecordNotFound
      klass = controller_name.classify.constantize
      @current = klass.try(:find_by_slug, params[:id])
    end
    instance_variable_set "@#{controller_name.singularize}", @current
    @parent = nil
    keys = params.keys
    regex = /(.+)_id/
    keys = keys.select{ |k| regex.match(k) }
    return if keys.nil? || keys.size == 0
    keys.each do |key|
      begin
        @parent = regex.match(key)[1].classify.constantize.find(params[key].to_i)
      rescue NameError
      rescue ActiveRecord::RecordNotFound
        klass = regex.match(key)[1].classify.constantize
        @parent = klass.try(:find_by_slug, params[key])
      end
      instance_variable_set "@#{regex.match(key)[1]}", @parent
    end
  end

end
