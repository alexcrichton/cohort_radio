class QueueItemsController < ApplicationController

  load_and_authorize_resource :playlist, :find_by => :slug
  load_and_authorize_resource :song
  load_and_authorize_resource

  respond_to :html, :js

  def create
    @playlist.enqueue @song, current_user

    Pusher['playlist-' + @playlist.slug].trigger 'added_item',
      :playlist_id => @playlist.to_param,
      :url => polymorphic_path([:queue, @playlist])

    respond_with @playlist
  end

  def destroy
    @playlist.queue_items.delete @queue_item

    Pusher['playlist-' + @playlist.slug].trigger 'removed_item',
      :playlist_id => @playlist.to_param, :queued_id => @queue_item.id

    respond_with @playlist
  end

end
