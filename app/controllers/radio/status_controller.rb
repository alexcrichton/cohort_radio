class Radio::StatusController < ApplicationController
  
  before_filter { |c| c.unauthorized! if c.cannot? :manage, Radio }
  
  before_filter :require_radio_running
  
  def index    
    @playlists = Playlist.all
  end
  
end
