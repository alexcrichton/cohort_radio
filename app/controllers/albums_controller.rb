class AlbumsController < ApplicationController

  load_and_authorize_resource :artist, :find_by => :slug
  load_and_authorize_resource :find_by => :slug

  respond_to :html, :js

  def index
    @albums = @artist ? @artist.albums : Album.scoped
    @albums = @albums.where(:name => /^#{params[:letter]}/i) if params[:letter]
    @albums = @albums.page(params[:page]).per(20)

    respond_with @albums
  end

  def show
    @songs = @album.songs.page(params[:page]).per(10)

    respond_with @album
  end

  def edit
    respond_with @album
  end

  def update
    @album.update_attributes params[:album]

    respond_with @album do |format|
      format.html { render @album }
    end
  end

end
