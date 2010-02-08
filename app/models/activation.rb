class Activation < ActiveRecord::Base
  
  belongs_to :user
  validates_presence_of :user
  validates_presence_of :state
  
  def pending?
    state == 'pending'
  end
  
  def activated?
    state == 'activated' || state == 'confirmed'
  end
  
  def confirmed?
    state == 'confirmed'
  end
  
  
end
