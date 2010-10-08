class AlbumsController < ApplicationController

  load_and_authorize_resource :artist, :find_by => :slug
  load_and_authorize_resource :find_by => :slug

  respond_to :html, :js

  def index
    @albums = Album.order('name').includes(:artist)
    @albums = @albums.where("name LIKE ?", "#{params[:letter]}%") if params[:letter]

    @albums = @albums.paginate :page => params[:page]

    respond_with @albums
  end

  def show
    @songs = @album.songs.paginate :page => params[:page], :per_page => 10

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
