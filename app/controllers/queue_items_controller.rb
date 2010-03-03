class QueueItemsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def new
    @playlist.enqueue @song, current_user unless @song.nil?
    
    if request.xhr?
      render :text => "<span class='notice'>Queued.</span>"
    else
      flash[:notice] = "#{@song.title} queued!" unless @song.nil?
      redirect_to @playlist
    end
  end
  
  def destroy
    @playlist.queue_items.delete @queue_item unless @queue_item.nil?
    
    if request.xhr?
      render :text => "<span class='notice'>Dequeued</span>"
    else
      flash[:notice] = "#{@queue_item.song.title} dequeued!" unless @queue_item.nil?
      redirect_to @playlist
    end
  end
  
end
