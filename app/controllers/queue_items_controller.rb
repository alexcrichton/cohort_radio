class QueueItemsController < ApplicationController

  load_and_authorize_resource :playlist, :find_by => :slug
  load_and_authorize_resource :song
  load_and_authorize_resource

  respond_to :html, :js

  def create
    @playlist.enqueue @song, current_user

    respond_with @playlist
  end

  def destroy
    @playlist.queue_items.delete @queue_item

    respond_with @playlist
  end

end
