class Ability
  include CanCan::Ability
  
  def initialize user, parent
    
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
      can [:read, :create], Playlist
      can :update, Playlist do |playlist|
        playlist.user_id == user.id
      end
      can [:download, :create, :search, :update], Song
      can :manage, user
      can [:read, :logout], User
      can [:search, :download], Fargo
      can :read, :all
      
      can :create, QueueItem do |queue_item|
        parent.is_a?(Playlist) && can?(:add_to, parent.pool)
      end
      
      can [:add_to, :remove_from], Pool do |pool|
        puts pool
        !pool.playlist.private || pool.playlist.users.include?(user)
      end
      
      can :destroy, QueueItem do |item|
        item.user_id == user.id
      end
      
    end
    
  end
end
