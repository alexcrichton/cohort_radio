class UserSessionsController < ApplicationController

  before_filter(:only => [:destroy]){ |c| c.unauthorized! if c.cannot? :logout, User}
  before_filter(:only => [:new, :create]){ |c| c.unauthorized! if c.cannot? :login, User}

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])

    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default root_path
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = 'Logged out!'
    redirect_to login_path
  end

end
