class SongsController < ApplicationController
  def index
    @songs = Song.paginate :page => params[:page]
  end
  
  def show
  end
  
  def new
    @song = Song.new
  end
  
  def create
    @song = Song.new(params[:song])
    if @song.save
      flash[:notice] = "Successfully created song."
      redirect_to @song
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @song.update_attributes(params[:song])
      flash[:notice] = "Successfully updated song."
      redirect_to @song
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @song.destroy
    flash[:notice] = "Successfully destroyed song."
    redirect_to songs_url
  end
end
