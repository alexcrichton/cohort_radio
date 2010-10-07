class ArtistsController < ApplicationController

  load_and_authorize_resource :find_by => :slug

  respond_to :html

  def index
    @artists = Artist.order('name')
    if params[:letter]
      @artists = @artists.where('name LIKE ?', "#{params[:letter]}%")
    end

    @artists = @artists.paginate :page => params[:page]

    respond_with @artists unless request.xhr?
  end

  def show
    @albums = @artist.albums.order('name').includes(:artist)

    respond_with @artist
  end

  def update
    @artist.update_attributes params[:artist]

    respond_with @artist do
      format.html { render @artist }
    end
  end

end
