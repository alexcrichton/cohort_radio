class Fargo::CommandsController < ApplicationController
  
  before_filter(:except => :download){ |c| c.unauthorized! if c.cannot? :manage, Fargo }
  before_filter(:only => :download){ |c| c.unauthorized! if c.cannot? :download, Fargo }  
  
  def connect
    fargo.connect
    flash[:notice] = "Connected!"

    redirect_to playlists_path
  end
  
  def disconnect
    fargo.disconnect
    flash[:notice] = "Disconnected!"
    
    redirect_to playlists_path
  end
  
  def download
    # Delayed::Job.enqueue DownloadSongJob.new(params[:nick], params[:file])
    fargo.download params[:nick], params[:file], params[:tth], params[:size].to_i

    if request.xhr?
      render :text => '<span class="notice">Queued</span>'
    else
      flash[:notice] = "Song was queued for download."
      redirect_to fargo_downloads_path
    end

  end
  
end
