class Ability
  include CanCan::Ability
  
  def initialize user, parent = nil
    
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
      can [:update, :add, :next, :stop], Playlist, :user_id => user.id
      can [:download, :create, :search, :update], Song
      can :manage, user
      can [:read, :logout], User
      can [:search, :download], Fargo
      can :read, :all
      
      can :create, Comment
      
      can :manage, Comment, :user_id => user.id
      
      # can :create, QueueItem do |queue_item|
      #   parent.nil? || (parent.is_a?(Playlist) && can?(:add_to, parent.pool))
      # end
      
      can :manage, Pool do |action, pool|
        !pool.playlist.private || pool.playlist.user_id == user.id || pool.playlist.user_ids.include?(user.id)
      end
      
      can :destroy, QueueItem, :user_id => user.id
      
      can [:create, :destroy], Membership do |membership|
        parent.is_a?(Playlist) && parent.user_id == user.id
      end
      
      can :create, QueueItem
    end
    
  end
end
