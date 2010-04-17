class Radio::StatusController < ApplicationController
  
  before_filter { |c| c.authorize! :manage, Radio }
  
  before_filter :require_radio_running
  
  def index    
    @playlists = Playlist.all
  end
  
end
