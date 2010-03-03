class PlaylistsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    @playlists = Playlist.scoped.paginate(:page => params[:page])
    respond_with @playlists unless request.xhr?
  end
  
  def show
    respond_with @playlist
  end
  
  def new
    respond_with @playlist = Playlist.new
  end
    
  def create
    @playlist = Playlist.new(params[:playlist])
    flash[:notice] = "Successfully created playlist." if @playlist.save
    respond_with @playlist
  end
  
  def edit
    respond_with @playlist
  end
  
  def update
    flash[:notice] = "Successfully updated playlist." if @playlist.update_attributes(params[:playlist])
    respond_with @playlist
  end
  
  def destroy
    @playlist.destroy
    redirect_to playlists_url, :notice => "Successfully destroyed playlist."
  end
  
end
