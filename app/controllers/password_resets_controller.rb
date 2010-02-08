class PasswordResetsController < ApplicationController

  before_filter :load_user_using_perishable_token, :only => [:edit, :update]
  before_filter { |c| c.unauthorized! if c.cannot? :reset, 'password' }

  def new
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user
      @user.deliver_password_reset_instructions!
      flash[:notice] = "Instructions to reset your password have been emailed to you. Please check your email."
      redirect_to root_path
    else
      flash[:error] = "No user was found with that email address"
      render :action => :new
    end
  end

  def edit
  end

  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.save
      flash[:notice] = "Password successfully updated"
      redirect_to @user
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
