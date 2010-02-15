class Fargo::CommandsController < ApplicationController
  
  def connect
    response = fargo.connect
    flash[:notice] = "Connected!"

    redirect_to playlist_path('main')
  end
  
  def disconnect
    response = fargo.disconnect
    puts response.inspect
    flash[:notice] = "Disconnected!"
    
    redirect_to playlist_path('main')
  end
  
  def download
    Delayed::Job.enqueue DownloadSongJob.new(params[:nick], params[:file])
    flash[:notice] = "Song was queued for download."
    redirect_to playlist_path('main')
  end
  
end
