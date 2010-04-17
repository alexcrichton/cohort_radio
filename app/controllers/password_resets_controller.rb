class PasswordResetsController < ApplicationController

  before_filter :load_user_using_perishable_token, :only => [:edit, :update]
  before_filter { |c| c.authorize! :reset, 'password' }

  def new
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user
      @user.deliver_password_reset_instructions!
      redirect_to login_path, :notice => "Instructions to reset your password have been emailed to you. Please check your email."
    else
      redirect_to [:new, :password_reset], :alert => "No user was found with that email address"
    end
  end

  def edit
  end

  def update
    @user.password              = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    
    if @user.save
      redirect_to :playlists, :notice => "Password successfully updated"
    else
      render :action => 'edit'
    end
  end

  private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    if @user.nil?
      flash[:error] = "We're sorry, but we could not locate your account. " +
        "If you are having issues try copying and pasting the URL " +
        "from your email into your browser or restarting the " +
        "reset password process."
      return redirect_to root_path
    end
  end
end
