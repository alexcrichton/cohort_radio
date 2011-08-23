class Ability
  include CanCan::Ability

  def initialize user, parent = nil
    alias_action :play_count, :queue, :to => :read
    can :manage, :all
  end
end
