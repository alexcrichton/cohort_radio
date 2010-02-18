class Ability
  include CanCan::Ability
  
  def initialize(user)
    
    can :home, User  
      
    if user.nil? || user.activation.nil? || user.activation.pending?
      can :login, User
      can :create, User
      can :reset, 'password'
      can [:create, :read, :activate], Activation
    elsif user.admin
      can :manage, :all
      cannot :reset, 'password' # need to be logged out (don't want to mess with other users)
    elsif user.confirmed?
      can [:read, :enqueue], Playlist
      can [:download, :create, :search, :update], Song
      can :manage, user
      can :read, User
      can :logout, User
      can :read, :all
      can [:search, :download], Fargo
    end
    
  end
end
