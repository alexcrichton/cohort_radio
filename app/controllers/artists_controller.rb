class ArtistsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    @artists = Artist.order('name')
    @artists = @artists.where("name LIKE ?", "#{params[:letter]}%") if params[:letter]
    
    @artists = @artists.paginate :page => params[:page]
    
    respond_with @artists
  end
  
  def show
    @albums = @artist.albums.order('name')
    
    respond_with @artist
  end
  
end
