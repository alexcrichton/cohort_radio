class QueueItemsController < ApplicationController

  load_and_authorize_resource :playlist, :find_by => :slug
  load_and_authorize_resource :song
  load_and_authorize_resource

  respond_to :html, :js

  def create
    @playlist.enqueue @song, current_user

    with_format 'html' do
      push :type => 'playlist.added_item', :playlist_id => @playlist.to_param,
        :html => render_to_string(:partial => 'playlists/queue')
    end

    respond_with @playlist
  end

  def destroy
    @playlist.queue_items.delete @queue_item

    push :type => 'playlist.removed_item', :song_id => @queue_item.song_id,
      :playlist_id => @playlist.to_param

    respond_with @playlist
  end

end
