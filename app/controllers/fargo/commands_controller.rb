class Fargo::CommandsController < ApplicationController
  
  authorize_resource :class => Fargo
  
  before_filter :require_fargo_connected, :except => :connect
  
  def connect
    fargo.connect

    redirect_back_or_default playlists_path, :notice => "Connected!"
  end
  
  def disconnect
    if params[:nick]
      fargo.disconnect_from params[:nick]
    else
      fargo.disconnect
    end
    
    redirect_back_or_default playlists_path, :notice => "Disconnected!"
  end
  
  def clear_finished_downloads
    fargo.clear_finished_downloads

    if request.xhr?
      render :text => '<span class="notice">Cleared</span>'
    else
      redirect_to fargo_downloads_path, :notice => "Finished downloads were cleared."
    end
  end
  
  def clear_failed_downloads
    fargo.clear_failed_downloads

    if request.xhr?
      render :text => '<span class="notice">Cleared</span>'
    else
      redirect_to fargo_downloads_path, :notice => "Failed downloads were cleared."
    end  
  end
  
  def download
    fargo.download params[:nick], params[:file], params[:tth], params[:size].to_i

    if request.xhr?
      render :text => '<span class="notice">Queued</span>'
    else
      redirect_to fargo_downloads_path, :notice => "Song was queued for download."
    end
  rescue Fargo::ConnectionException
    if request.xhr?
      render :text => '<span class="alert">User no longer exists!</span>'
    else
      redirect_to fargo_downloads_path, :alert => "User no longer exists!."
    end
  end
  
end
