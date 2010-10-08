class SongsController < ApplicationController

  load_and_authorize_resource

  respond_to :html, :js, :json

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

    if params[:letter]
      @songs = @songs.where("title LIKE ?", "#{params[:letter]}%")
    end

    @songs = @songs.includes(:album, :artist)
    @songs = @songs.paginate :page => params[:page], :per_page => 10

    respond_with @songs unless request.xhr?
  end

  def show
    respond_with @song do |format|
      format.mp3 { send_file @song.audio.path, :type => 'audio/mpeg' }
    end
  end

  def new
    respond_with @song
  end

  def create
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

    push :type => 'song.rating', :song_id => @song.id, :rating => @song.rating

    respond_with @song
  end

  def update
    @song.update_attributes params[:song]

    push :type => 'song.updated', :song_id => @song.id, :url => url_for(@song)

    respond_with @song
  end

  def destroy
    @song.destroy

    push :type => 'song.destroyed', :song_id => @song.id

    respond_with @song do |format|
      format.html { redirect_back_or_default songs_path }
    end
  end

  def search
    @songs = params[:q].blank? ? [] : Song.search(params[:q])
    if params[:completion].blank?
      @songs = @songs.paginate :page => params[:page], :per_page => 10
    end

    @songs = @songs.limit params[:limit] || 10

    respond_with @songs do |format|
      format.json {
        render :json => @songs.map{ |s|
          {:value => s.id, :title => s.title, :artist => s.artist.name,
            :image => "<img src='#{s.album.cover_url}' height='30px'/>"}
        }
      }
    end
  end

end
