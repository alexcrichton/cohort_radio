class Radio::StatusController < ApplicationController
  
  before_filter { |c| c.unauthorized! if c.cannot? :manage, Radio }
  
  def index    
    @playlists = Playlist.all
  end
  
end
