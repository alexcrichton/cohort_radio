class SongsController < ApplicationController
  
  def index
    @songs = Song.scoped.paginate :page => params[:page]
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
      redirect_to playlist_path('main')
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
  
  def download
    puts @song.audio.path
    send_file @song.audio.path
  end
  
  def destroy
    @song.destroy
    flash[:notice] = "Successfully destroyed song."
    redirect_to songs_url
  end
  
  def search
    @songs = Song.limit(params[:limit]).where('title LIKE ?', "%#{params[:q]}%")
    render :text => @songs.map { |s| "<img src='#{s.album_image_url}' height='30px'/> #{s.title} - #{s.artist} (#{s.id})\n" }
  end
  
end
