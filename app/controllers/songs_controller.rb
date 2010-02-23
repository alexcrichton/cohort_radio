class SongsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    respond_with(@songs = Song.paginate(:page => params[:page]))
  end
  
  def show
  end
  
  def new
    respond_with @song = Song.new
  end
  
  def create
    @song = Song.new(params[:song])
    flash[:notice] = 'Song created!' if @song.save
    respond_with @song
  end
  
  def edit
    respond_with @song
  end
  
  def update
    flash[:notice] = "Song updated!" if @song.update_attributes params[:song]
    respond_with @song
  end
  
  def download
    puts @song.audio.path, @song.audio_content_type
    # need stream => false with rails 3 because for some reason it doesn't work otherwise...
    send_file @song.audio.path, :type => @song.audio_content_type, :stream => false
  end
  
  def destroy
    @song.destroy
    redirect_to songs_path, :notice => "Successfully destroyed song."
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
