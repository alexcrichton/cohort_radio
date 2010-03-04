class ArtistsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    @artists = Artist.order('name')
    @artists = @artists.where("name LIKE ?", "#{params[:letter]}%") if params[:letter]
    
    @artists = @artists.paginate :page => params[:page]
    
    respond_with @artists unless request.xhr?
  end
  
  def show
    @albums = @artist.albums.order('name')
    
    respond_with @artist
  end
  
  def update
    @artist.update_attributes params[:artist]
    render @artist
  end
  
  
end
