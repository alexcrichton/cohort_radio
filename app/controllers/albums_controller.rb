class AlbumsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    @albums = Album.order('name')
    @albums = @albums.where("name LIKE ?", "#{params[:letter]}%") if params[:letter]
    
    @albums = @albums.paginate :page => params[:page]
          
    respond_with @albums unless request.xhr?
  end
  
  def show
    @album  = @artist.albums.find_by_slug params[:id]
    @songs  = @album.songs.paginate :page => params[:page], :per_page => 10
  end
  
  def update
    @album.update_attributes params[:album]
    render @album
  end
  
end
