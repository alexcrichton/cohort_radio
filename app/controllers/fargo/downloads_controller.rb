class Fargo::DownloadsController < ApplicationController

  def index
    @items = Delayed::Job.all
    @items.reject! { |j| !j.payload_object.is_a?(DownloadSongJob) }
  end
  
  def destroy
    @job = Delayed::Job.find(params[:id])
    @job.destroy
    flash[:notice] = "Download removed"
    redirect_to fargo_downloads_path
  end
end
