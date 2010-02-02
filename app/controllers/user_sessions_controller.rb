class UserSessionsController < ApplicationController

  before_filter :require_user, :only => [:destroy]
  before_filter :require_no_user, :only => [:new]
  
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
