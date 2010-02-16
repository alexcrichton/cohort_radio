class UsersController < ApplicationController
  
  authorize_resource
  
  def home
    redirect_to current_user ? playlists_path : login_path
  end
  
  def show
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])

    # Saving without session maintenance to skip auto-login which can't happen here because
    # the user has not yet been activated
    if @user.save_without_session_maintenance
      @user.deliver_activation_instructions!
      flash[:notice] = "Account created! Please check your email for activation instructions."
      redirect_to login_path
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated user."
      redirect_to @user
    else
      render :action => 'edit'
    end
  end
  
  def adminize
    @user.admin = params[:user][:admin]
    Notifier.send_later :deliver_admin_notification, @user if @user.save
    render :text => (params[:user][:admin] == '1' ? 'Adminized' : 'Revoked')
  end
  
  def destroy
    @user.destroy
    flash[:notice] = "Successfully destroyed user."
    redirect_to users_url
  end
  
end
