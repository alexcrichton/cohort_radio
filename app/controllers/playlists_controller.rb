class PlaylistsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    respond_with(@playlists = Playlist.scoped.paginate(:page => params[:page]))
  end
  
  def show
    respond_with @playlist
  end
  
  def new
    respond_with @playlist = Playlist.new
  end
  
  def enqueue
    @playlist.enqueue @song, current_user unless @song.nil?
    
    if request.xhr?
      render @song ? @song : {:text => ''}
    else
      flash[:notice] = "#{@song.display_title} queued!" unless @song.nil?
      redirect_to @playlist
    end
  end
  
  def dequeue
    @playlist.songs.delete @song unless @song.nil?
    flash[:notice] = "#{@song.display_title} dequeued!" unless @song.nil?
    redirect_to @playlist
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
