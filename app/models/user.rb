class User < ActiveRecord::Base
  acts_as_authentic
  
  has_many :queue_items
  has_and_belongs_to_many :playlists

  attr_accessible :name, :email, :password, :password_confirmation
  has_one :activation, :dependent => :destroy
  after_create :create_activation
  
  scope :state, lambda{ |state| includes(:activation).where('activations.state = ?', state) }
  scope :admins, where(:admin => true)
  
  def active?
    activation && activation.activated?
  end

  def confirmed?
    activation && activation.confirmed?
  end

  def deliver_activation_instructions!
    Activation.create(:state => 'pending', :user => self)
    reset_perishable_token!
    Notifier.send_later :deliver_activation_instructions, self
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.send_later :deliver_password_reset_instructions, self
  end
end
