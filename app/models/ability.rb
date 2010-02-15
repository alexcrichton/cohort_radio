class Ability
  include CanCan::Ability
  
  def initialize(user)
        
    if user.nil? || user.activation.nil? || user.activation.pending?
      can :login, User
      can :create, User
      can :reset, 'password'
      can [:create, :read], Activation
    elsif user.admin
      can :manage, :all
      cannot :reset, 'password' # need to be logged out (don't want to mess with other users)
    elsif user.confirmed?
      can :read, Playlist
      can [:download, :create], Song
      can :manage, user
      can :read, User
      can :read, :all
    end
  end
end
