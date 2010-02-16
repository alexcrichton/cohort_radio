class PlaylistsController < ApplicationController
  
  authorize_resource
  
  def index
    @playlists = Playlist.all.paginate :page => params[:page]
  end
  
  def show
  end
  
  def new
    @playlist = Playlist.new
  end
  
  def enqueue
    @playlist.songs << @song
    redirect_to @playlist
  end
  
  def create
    @playlist = Playlist.new(params[:playlist])
    if @playlist.save
      flash[:notice] = "Successfully created playlist."
      redirect_to @playlist
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @playlist.update_attributes(params[:playlist])
      flash[:notice] = "Successfully updated playlist."
      redirect_to @playlist
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @playlist.destroy
    flash[:notice] = "Successfully destroyed playlist."
    redirect_to playlists_url
  end
end
