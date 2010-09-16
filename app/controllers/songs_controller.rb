class SongsController < ApplicationController

  authorize_resource

  respond_to :html
  respond_to :js, :only => :rate

  def index
    top_level = Song
    top_level = @parent.songs if @parent

    if params[:order] == 'play_count'
      @songs = top_level.order 'play_count DESC'
    elsif params[:order] == 'rating'
      @songs = top_level.order 'rating DESC'
    else
      @songs = top_level.order 'title'
    end
    @songs = @songs.where("title LIKE ?", "#{params[:letter]}%") if params[:letter]

    @songs = @songs.includes(:album, :artist)
    @songs = @songs.paginate :page => params[:page], :per_page => 10

    respond_with @songs unless request.xhr?
  end

  def artists
    @artists = Song.order(:artist).group(:artist).paginate :page => params[:page]
  end

  def show
    respond_with @song do |format|
      format.mp3 { send_file @song.audio.path, :type => 'audio/mpeg' }
    end
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

  def rate
    scope = @song.ratings.by current_user

    if @rating = scope.first
      @rating.update_attributes! params[:rating]
    else
      @rating = scope.build params[:rating]
      @rating.user = current_user
      @rating.save! # we expect this to work
    end

    @song.reload # Our rating has changed

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

  def destroy
    @song.destroy

    redirect_back_or_default songs_path, :notice => "Successfully destroyed song."
  end

  def search
    @songs = params[:q].blank? ? [] : Song.search(params[:q])
    @songs = @songs.paginate :page => params[:page], :per_page => 10 if params[:completion].blank?

    if request.xhr?
      if params[:completion]
        @songs = @songs.limit params[:limit]
        render :text => @songs.map { |s| "<img src='#{s.album.cover_url}' height='30px'/> #{s.title} - #{s.artist.name} (#{s.id})" }.join("\n")
      end
    end
  end

end
