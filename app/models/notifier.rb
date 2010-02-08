class Notifier < ActionMailer::Base
  
  default smtp_settings[:user_name]

  def password_reset_instructions(user)
    @edit_password_reset_url = edit_password_reset_url(user.perishable_token)
    mail :to => user.email, :subject => 'Cohort Radio Password Reset Instructions'
  end

  def activation_instructions(user)
    @account_activation_url = user_activate_url(user.perishable_token),
    @resend_activation_url = new_activation_url(user.email)
    mail :to => user.email, :subject => 'Cohort Radio Activation Instructions'
  end

  def confirmation_request(user)
    admins = User.admins.map{|u| u.email}
    @user = user
    @confirm_url = edit_activation_url
    mail :to => admins.shift, :bcc => admins, :subject => 'Cohort Radio Confirmation Request'
  end

  def confirmation_notification(user)
    @user = user
    mail :to => user.email, :subject => 'Cohort Radio Membership Confirmed'
  end

  def revokation_notification(user)
    @user = user
    mail :to => user.email, :subject => 'Cohort Radio Membership Revoked'
  end

  def admin_notification(user)
    @user = user
    mail :to => user.email, :subject => 'Cohort Radio Admin Status'
  end

end
