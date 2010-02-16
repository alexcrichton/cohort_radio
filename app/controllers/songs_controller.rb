class SongsController < ApplicationController
  
  authorize_resource
  
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
      redirect_to playlists_path
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    puts params[:song].inspect
    if @song.update_attributes(params[:song])
      flash[:notice] = "Successfully updated song."
      redirect_to @song
    else
      render :action => 'edit'
    end
  end
  
  def download
    send_file @song.audio.path, :type => @song.audio_content_type
  end
  
  def destroy
    @song.destroy
    flash[:notice] = "Successfully destroyed song."
    redirect_to songs_path
  end
  
  def search
    @songs = Song.limit(params[:limit]).where('title LIKE ?', "%#{params[:q]}%")
    render :text => @songs.map { |s| "<img src='#{s.album_image_url}' height='30px'/> #{s.title} - #{s.artist} (#{s.id})\n" }
  end
  
end
