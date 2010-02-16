class Fargo::CommandsController < ApplicationController
  
  before_filter { |c| c.unauthorized! if c.cannot? :manage, Fargo }
  
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
    flash[:notice] = "Song was queued for download."
    redirect_to playlists_path
  end
  
end
