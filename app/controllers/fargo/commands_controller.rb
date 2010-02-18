class Fargo::CommandsController < ApplicationController
  
  before_filter(:except => :download){ |c| c.unauthorized! if c.cannot? :manage, Fargo }
  before_filter(:only => :download){ |c| c.unauthorized! if c.cannot? :download, Fargo }  
  
  def connect
    response = fargo.connect
    flash[:notice] = "Connected!"

    redirect_to playlists_path
  end
  
  def disconnect
    response = fargo.disconnect
    puts response.inspect
    flash[:notice] = "Disconnected!"
    
    redirect_to playlists_path
  end
  
  def download
    Delayed::Job.enqueue DownloadSongJob.new(params[:nick], params[:file])

    if request.xhr?
      render :text => '<span class="notice">Queued</span>'
    else
      flash[:notice] = "Song was queued for download."
      redirect_to fargo_downloads_path
    end

  end
  
end
