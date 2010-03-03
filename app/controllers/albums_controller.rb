class AlbumsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    @albums = Albums.paginate :page => params[:page], :per_page => 10
    
    if request.xhr?
      render :inline => "<% paginated_section @albums do %><%= render @albums %><% end %>"
    else
      respond_with @artists
    end
  end
  
  def show
    @songs = @album.songs
    @artist = @album.artist
  end
  
end
