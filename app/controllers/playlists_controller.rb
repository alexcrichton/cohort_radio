class PlaylistsController < ApplicationController

  load_and_authorize_resource :find_by => :slug

  respond_to :html

  def index
    @playlists = @playlists.paginate(:page => params[:page])

    respond_with @playlists
  end

  def show
    respond_with @playlist
  end

  def new
    respond_with @playlist
  end

  def create
    flash[:notice] = 'Successfully created playlist.' if @playlist.save

    respond_with @playlist
  end

  def edit
    respond_with @playlist
  end

  def queue
    respond_with @playlist
  end

  def update
    if @playlist.update_attributes params[:playlist]
      flash[:notice] = 'Successfully updated playlist.'
    end

    respond_with @playlist
  end

  def destroy
    @playlist.destroy
    respond_with @playlist, :notice => 'Successfully destroyed playlist.'
  end

end
