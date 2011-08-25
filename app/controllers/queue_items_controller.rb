class QueueItemsController < ApplicationController

  load_and_authorize_resource :playlist, :find_by => :slug
  load_and_authorize_resource :song
  load_and_authorize_resource :through => :playlist

  respond_to :html, :js

  def create
    @queue_item.song = @song
    @queue_item.user = current_user
    @queue_item.enqueue!

    Pusher['playlist-' + @playlist.to_param].trigger 'added_item',
      :playlist_id => @playlist.to_param,
      :url => polymorphic_path([:queue, @playlist])

    respond_with @playlist
  end

  def destroy
    @queue_item.destroy

    Pusher['playlist-' + @playlist.to_param].trigger 'removed_item',
      :playlist_id => @playlist.to_param, :queue_id => @queue_item.id

    respond_with @playlist
  end

end
