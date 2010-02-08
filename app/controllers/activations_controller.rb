class ActivationsController < ApplicationController

  authorize_resource

  # Form for emailing a user's activation code
  def new
    @email = params[:email]
  end

  # Explain to a user that they are pending confirmation
  def show
  end

  # Deliver an activation email to a user
  def create
    @user = User.find_by_email(params[:email])
    if @user
      @user.deliver_activation_instructions!
      flash[:notice] = "Please check your email for activation instructions."
      redirect_to login_path
    else
      flash[:error] = "No user was found with that email address"
      render :action => :new
    end
  end

  # Use the activation code to activate a user
  def activate
    @user = User.find_using_perishable_token(params[:token], 2.days)
    if @user.nil?
      flash[:notice] = 'Your token is incorrect or has expired, resend your activation instructions to correct this.'
      redirect_to login_path
    else
      @user.activation.update_attributes(:state => 'activated')
      flash[:notice] = 'Your account is now activated.'
      Notifier.send_later :deliver_confirmation_request, @user
      redirect_to activation_path
    end
  end

  # Show pending confirmations/activations
  def edit
    @pending = User.state 'pending'
    @activated = User.state 'activated'
    @confirmed = User.state 'confirmed'
  end

  # Confirm the accounts
  def update
    @user = User.find(params[:user][:id])
    @operation = params[:op]
    case @operation
      when 'activate'
        @success = @user.deliver_activation_instructions!
      when 'confirm'
        Notifier.send_later(:deliver_confirmation_notification, @user) if @success = @user.activation.update_attributes(:state => 'confirmed')
      when 'revoke'
        Notifier.send_later(:deliver_revokation_notification, @user) if @success = @user.activation.update_attributes(:state => 'activated')
    end
    render :text => @success ? @user.id : 'error'
  end

  def form
    render :partial => params[:form], :locals => {:user => @user}
  end

end
