class Ability
  include CanCan::Ability

  def initialize user, parent = nil
    alias_action :play_count, :to => :read

    can :home, User

    if user.nil? || user.confirmed_at.nil?
      can :login, User
      can :create, User
      can :reset, 'password'
    elsif user.admin
      can :manage, :all
      cannot :reset, 'password' # need to be logged out (don't want to mess with other users)
    else
      can [:read, :create], Playlist
      can [:update, :add, :next, :stop], Playlist, :user_id => user.id
      can [:create, :search, :update, :rate], Song
      can :manage, user
      can [:read, :logout], User
      can [:search, :download], Fargo
      can :read, :all

      can :create, Comment

      can :manage, Comment, :user_id => user.id

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
