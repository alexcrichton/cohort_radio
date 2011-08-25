class ArtistsController < ApplicationController

  load_and_authorize_resource :find_by => :slug

  respond_to :html, :js

  def index
    @artists = Artist.order_by(:name)
    if params[:letter]
      @artists = @artists.where(:name => /^#{params[:letter]}/i)
    end
    @artists = @artists.page(params[:page]).per(20)

    respond_with @artists
  end

  def edit
    respond_with @artist
  end

  def show
    @albums = @artist.albums.order('name')

    respond_with @artist
  end

  def update
    @artist.update_attributes params[:artist]

    respond_with @artist do |format|
      format.html { render @artist }
    end
  end

end
