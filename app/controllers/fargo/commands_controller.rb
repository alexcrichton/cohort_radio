class Fargo::CommandsController < ApplicationController
  
  before_filter(:except => :download){ |c| c.unauthorized! if c.cannot? :manage, Fargo }
  before_filter(:only => :download){ |c| c.unauthorized! if c.cannot? :download, Fargo }  
  
  before_filter :require_fargo_running, :except => :connect
  
  def connect
    fargo.connect
    flash[:notice] = "Connected!"

    redirect_to playlists_path
  end
  
  def disconnect
    if params[:nick]
      fargo.disconnect_from params[:nick]
    else
      fargo.disconnect
    end

    flash[:notice] = "Disconnected!"
    
    redirect_to playlists_path
  end
  
  def clear_finished_downloads
    fargo.clear_finished_downloads

    if request.xhr?
      render :text => '<span class="notice">Cleared</span>'
    else
      flash[:notice] = "Finished downloads were cleared."
      redirect_to fargo_downloads_path
    end
    
  end
  
  def clear_failed_downloads
    fargo.clear_failed_downloads

    if request.xhr?
      render :text => '<span class="notice">Cleared</span>'
    else
      flash[:notice] = "Failed downloads were cleared."
      redirect_to fargo_downloads_path
    end
    
  end
  
  def download
    fargo.download params[:nick], params[:file], params[:tth], params[:size].to_i

    if request.xhr?
      render :text => '<span class="notice">Queued</span>'
    else
      flash[:notice] = "Song was queued for download."
      redirect_to fargo_downloads_path
    end

  end
  
end
