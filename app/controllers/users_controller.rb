class UsersController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def home
    redirect_to current_user ? playlists_path : login_path
  end
  
  def show
    respond_with @song
  end
  
  def new
    @user = User.new
  end
  
  def create
    respond_with(@user = User.new(params[:user])) do |format|
      format.html {
        # Saving without session maintenance to skip auto-login which can't happen here because
        # the user has not yet been activated
        if @user.save_without_session_maintenance
          @user.deliver_activation_instructions!
          redirect_to login_path, :notice => "Account created! Please check your email for activation instructions."
        else
          render :action => 'new'
        end        
      }
    end
  end
  
  def edit
    respond_with @song
  end
  
  def update

    flash[:notice] = "Successfully updated user." if @user.update_attributes(params[:user])
    respond_with @user
  end
  
  def adminize
    @user.admin = params[:user][:admin]
    Notifier.send_later :deliver_admin_notification, @user if @user.save
    render :text => (params[:user][:admin] == '1' ? 'Adminized' : 'Revoked')
  end
  
  def destroy
    @user.destroy
    redirect_to edit_activation_url, :notice => "Successfully destroyed user."
  end
  
end
