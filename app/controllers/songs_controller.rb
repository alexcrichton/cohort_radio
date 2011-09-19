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
      format.html { render(@song) }
    end
  end

  def new
    respond_with @song
  end

  def create
    audio = params.fetch(:song, {})[:audio]

    if audio && audio.size < 20.megabytes
      flash[:notice] = 'File queued for processing!'
      filename = Rails.root.join('tmp', SecureRandom.hex(20))
      filename.open('wb') { |f| f << audio.read }
      Resque.enqueue DownloadSongUpload,
                     download_user_upload_url(filename.basename)
      redirect_to root_path
    else
      flash.now[:error] = 'Need a file less than 20MB'
      render :action => 'new'
    end
  end

  def edit
    respond_with @song
  end

  def update
    @song.update_attributes params[:song]

    Pusher['song'].trigger('updated', :song_id => @song.id,
                                      :url => song_path(@song))

    respond_with @song
  end

  def destroy
    @song.destroy

    Pusher['song'].trigger('destroyed', :song_id => @song.id)

    respond_with @song do |format|
      format.html { redirect_back_or_default songs_path }
    end
  end

  def search
    @songs = Song.search(params[:q] || params[:term])
    @songs = @songs.limit params[:limit] || 10
    if params[:completion].blank?
      @songs = @songs.page(params[:page]).per(10)
    end

    respond_with @songs do |format|
      format.json {
        render :json => @songs.map{ |s|
          {:name => s.title, :artist => s.artist.name, :id => s.id,
           :image => "<img src='#{s.album.cover_url}' height='30px'/>"}
        }
      }
    end
  end

  def download_user_upload
    file = Rails.root.join('tmp').join File.basename(params[:file])
    if file.exist?
      if params[:delete].present?
        file.delete
        render :nothing => true
      else
        send_file file
      end
    else
      render :file => Rails.root.join('public/404.html'), :status => 404
    end
  end

end
