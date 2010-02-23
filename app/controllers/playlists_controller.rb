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
      render :text => "<span class='notice'>Queued.</span>"
    else
      flash[:notice] = "#{@song.display_title} queued!" unless @song.nil?
      redirect_to @playlist
    end
  end
  
  def dequeue
    @playlist.queue_items.delete @queue_item unless @queue_item.nil?
    
    if request.xhr?
      render :text => "<span class='notice'>Dequeued</span>"
    else
      flash[:notice] = "#{@queue_item.song.display_title} dequeued!" unless @queue_item.nil?
      redirect_to @playlist
    end
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
