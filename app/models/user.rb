class User < ActiveRecord::Base
  acts_as_authentic

  attr_accessible :name, :email, :password, :password_confirmation

  named_scope :admins, :conditions => {:admin => true}

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end
end
