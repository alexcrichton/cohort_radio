class SongsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    top_level = Song
    top_level = @parent.songs if @parent
    
    if params[:order] == 'play_count'
      @songs = top_level.order params[:order]
    else
      @songs = top_level.order 'title'
    end
    @songs = @songs.where("title LIKE ?", "#{params[:letter]}%") if params[:letter]
    
    @songs = @songs.paginate :page => params[:page], :per_page => 10
    
    respond_with @songs unless request.xhr?
  end
  
  def play_count
    top_level = Song
    top_level = @parent.songs if @parent
    
    @songs = top_level.order('play_count DESC')
    
    @songs = @songs.paginate :page => params[:page], :per_page => 10
  end
  
  def artists
    @artists = Song.order(:artist).group(:artist).paginate :page => params[:page]
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
    if request.xhr?
      render @song
    else
      respond_with @song
    end
  end
  
  def download
    send_file @song.audio.path, :type => @song.audio_content_type
  end
  
  def destroy
    @song.destroy
    
    redirect_back_or_default songs_path, :notice => "Successfully destroyed song."
  end
  
  def search
    @songs = params[:q].blank? ? [] : Song.search(params[:q])
    @songs = @songs.paginate :page => params[:page], :per_page => 10 if params[:completion].blank?
    if request.xhr?
      if params[:completion].blank?
        if @songs.size == 0
          render :text => "<h4>No results found!</h4>"
        else
          render :inline => "<%= raw(paginated_section @songs do %><%= render @songs %><% end) %>"
        end
      else
        @songs = @songs.limit params[:limit]
        render :text => @songs.map { |s| "<img src='#{s.album.cover_url}' height='30px'/> #{s.title} - #{s.artist.name} (#{s.id})" }.join("\n")
      end
    end
  end
  
end
