class PoolsController < ApplicationController
  
  authorize_resource
  
  def show
    @songs = @playlist.pool.songs.paginate :page => params[:page]
  end
  
  def add_to
    @playlist.pool.songs << @song
    
    if request.xhr?
      render :text => "<span class='notice'>Added</span>"
    else
      flash[:notice] = "Song added to pool"
      redirect_to playlist_pool_path(@playlist)
    end
  end
  
  def remove_from
    @playlist.pool.songs.delete @song
    
    if request.xhr?
      render :text => "<span class='notice'>Removed</span>"
    else
      flash[:notice] = "Song removed from pool"
      redirect_to playlist_pool_path(@playlist)
    end
  end
  
end
