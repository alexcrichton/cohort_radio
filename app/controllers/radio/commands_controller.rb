class Radio::CommandsController < ApplicationController
  
  before_filter { |c| c.unauthorized! if c.cannot? :manage, Radio }
  
  def connect
    radio.connect
    flash[:notice] = "Connected!"

    redirect_to playlist_path('main')
  end
  
  def add
    radio.add @playlist
    
    flash[:notice] = "Playlist #{@playlist.name} added!"
    redirect_to :controller => 'radio/status'
  end
  
  def stop
    radio.remove @playlist
    
    flash[:notice] = "Playlist #{@playlist.name} removed!"
    redirect_to :controller => 'radio/status'
  end
  
  def next
    radio.next @playlist
    
    flash[:notice] = "Next sent."
    redirect_to :controller => 'radio/status'
  end
  
  def disconnect
    radio.disconnect
    flash[:notice] = "Disconnected!"
    
    redirect_to :controller => 'radio/status'
  end
  
end
