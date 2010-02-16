class Fargo::DownloadsController < ApplicationController

  before_filter { |c| c.unauthorized! if c.cannot? :manage, Fargo }
  
  def index
    @jobs = Delayed::Job.all
    @jobs.reject! { |j| !j.payload_object.is_a?(DownloadSongJob) }
  end
  
  def destroy
    @job = Delayed::Job.find(params[:id])
    @job.destroy
    flash[:notice] = "Download removed"
    redirect_to fargo_downloads_path
  end
  
end
