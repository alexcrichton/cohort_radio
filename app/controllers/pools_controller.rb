class PoolsController < ApplicationController
  
  authorize_resource
  
  def show
    @pool = @playlist.pool
    @songs = @playlist.pool.songs.paginate :page => params[:page], :per_page => 10
    if request.xhr?
      render :inline => '<% paginated_section @songs do %><%= render @songs %><% end %>'
    end
  end
  
  def add
    @playlist.pool.songs << @song unless @playlist.pool.songs.include?(@song)
    
    if request.xhr?
      render :text => "<span class='notice'>Added</span>"
    else
      flash[:notice] = "Song added to pool"
      redirect_to playlist_pool_path(@playlist)
    end
  end
  
  def remove
    @playlist.pool.songs.delete @song 
    
    if request.xhr?
      render :text => "<span class='notice'>Removed</span>"
    else
      flash[:notice] = "Song removed from pool"
      redirect_to playlist_pool_path(@playlist)
    end
  end
  
end
