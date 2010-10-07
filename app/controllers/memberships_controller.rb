class MembershipsController < ApplicationController

  load_resource :playlist, :find_by => :slug
  load_and_authorize_resource

  respond_to :js

  def create
    @membership.playlist = @playlist
    @membership.save

    respond_with @membership
  end

  def destroy
    @playlist.memberships.delete @membership

    respond_with @playlist
  end

end
