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
    @songs = params[:q].blank? ? [] : Song.search(params[:q])
    @songs = @songs.paginate :page => params[:page], :per_page => 10 if params[:completion].blank?
    if request.xhr?
      if params[:completion].blank?
        if @songs.size == 0
          render :text => "<h4>No results found!</h4>"
        else
          render :inline => "<% paginated_section @songs do %><%= render @songs %><% end %>"
        end
      else
        @songs = @songs.limit params[:limit]
        render :text => @songs.map { |s| "<img src='#{s.album_image_url}' height='30px'/> #{s.title} - #{s.artist} (#{s.id})\n" }
      end
    end
  end
  
end
