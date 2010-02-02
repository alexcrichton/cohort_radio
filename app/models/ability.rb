class Ability
  include CanCan::Ability
  
  def initialize(user)
    alias_action :valid, :to => :validate
    
    can :create, School do 
      Settings.deadline.blank? || Time.now < Settings.deadline
    end
    can :validate, School
    
    if user.nil?
      can :login, User
      can :reset, 'password'
    elsif user.admin
      can :manage, :all
      cannot :reset, 'password' # need to be logged out (don't want to mess with other users)
    else
      can :logout, User
      can [:read, :update], user
    end
  end
end
