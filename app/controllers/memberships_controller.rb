class MembershipsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def create
    @playlist.users << @user unless @user.nil?
    
    if request.xhr?
      render :text => "<span class='notice'>Added.</span>"
    else
      flash[:notice] = "#{@user.name} added to playlist!" unless @user.nil?
      redirect_to edit_playlist_path(@playlist)
    end
  end
  
  def destroy
    @playlist.memberships.delete @membership
    
    if request.xhr?
      render :text => "<span class='notice'>Removed</span>"
    else
      flash[:notice] = "#{@user.name} removed!" unless @user.nil?
      redirect_to edit_playlist_path(@playlist)
    end
  end
  
end
