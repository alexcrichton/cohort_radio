class SongsController < ApplicationController

  load_resource :artist, :find_by => :slug
  load_and_authorize_resource

  respond_to :html, :js

  def index
    top_level = Song
    top_level = @artist.songs if @artist

    if params[:order] == 'play_count'
      @songs = top_level.order_by :play_count.desc
    else
      @songs = top_level.order_by :title.asc
    end

    if params[:letter]
      @songs = @songs.where(:title => /^#{params[:letter]}/i)
    end

    @songs = @songs.page(params[:page]).per(10)

    respond_with @songs
  end

  def show
    respond_with @song do |format|
      format.mp3 { send_file @song.audio.path, :type => :mp3 }
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

  def update
    @song.update_attributes params[:song]

    push :type => 'song.updated', :song_id => @song.id,
      :url => song_path(@song)

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
    @songs = Song.search(params[:q])

    @songs = @songs.limit params[:limit] || 10

    if params[:completion].blank?
      @songs = @songs.paginate :page => params[:page], :per_page => 10
    end

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
