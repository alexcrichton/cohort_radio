class Fargo::DownloadsController < ApplicationController

  before_filter(:except => :index){ |c| c.unauthorized! if c.cannot? :manage, Fargo }
  before_filter(:only => :index){ |c| c.unauthorized! if c.cannot? :download, Fargo }
    
  def index
    @jobs = Delayed::Job.all
    @jobs.reject! { |j| !j.payload_object.is_a?(DownloadSongJob) }
  end
  
  def retry
    @job = Delayed::Job.find params[:id]
    @job.update_attributes :run_at => Time.now + 1.second
    flash[:notice] = "Retrying download. Give it a few seconds to update and/or propagate"
    redirect_to fargo_downloads_path
  end
  
  def destroy
    @job = Delayed::Job.find(params[:id])
    @job.destroy
    flash[:notice] = "Download removed"
    redirect_to fargo_downloads_path
  end
  
end
