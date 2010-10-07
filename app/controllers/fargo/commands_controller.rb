class Fargo::CommandsController < ApplicationController

  authorize_resource :class => Fargo

  before_filter :require_fargo_connected, :except => :connect
  respond_to :js

  def connect
    fargo.connect

    redirect_back_or_default playlists_path, :notice => "Connected!"
  end

  def disconnect
    fargo.disconnect

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

    respond_with 'Downloading!'
  end

end
