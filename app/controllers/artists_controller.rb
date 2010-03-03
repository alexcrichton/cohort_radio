class ArtistsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    @artists = Artist.paginate :page => params[:page], :per_page => 10
    
    # Hack a solution for now. This doesn't work with just respond_with in production for some reason...
    if request.xhr?
      render :inline => "<% paginated_section @artists do %><%= render @artists %><% end %>"
    else
      respond_with @artists
    end
  end
  
  def show
    @albums = @artist.albums
    
    respond_with @artist
  end
  
end
