class Fargo::DownloadsController < ApplicationController

  before_filter(:except => :index){ |c| c.unauthorized! if c.cannot? :manage, Fargo }
  before_filter(:only => :index){ |c| c.unauthorized! if c.cannot? :download, Fargo }
    
  def index
    @current_downloads = fargo.current_downloads
    @queued_downloads = fargo.queued_downloads
    @failed_downloads = fargo.failed_downloads
    @finished_downloads = fargo.finished_downloads
    
    @jobs = Delayed::Job.all
    @jobs.reject!{ |j| !j.payload_object.is_a?(CreateSongJob) }
  end
  
  def retry
    fargo.retry_download params[:nick], params[:file]
    
    if request.xhr?
      render :text => '<span class="notice">Queued</span>'
    else
      flash[:notice] = "Retrying download. Give it a few seconds to update and/or propagate"
      redirect_to fargo_downloads_path
    end
  end
  
  def remove
    @job = Delayed::Job.find params[:id]
    @job.destroy
    
    if request.xhr?
      render :text => '<span class="notice">Removed</span>'
    else
      flash[:notice] = "Retrying download. Give it a few seconds to update and/or propagate"
      redirect_to fargo_downloads_path
    end
    
  end
  
  def destroy
    fargo.remove_download params[:nick], params[:file]

    if request.xhr?
      render :text => 'success'
    else
      flash[:notice] = "Download removed"
      redirect_to fargo_downloads_path
    end
  end
  
end
