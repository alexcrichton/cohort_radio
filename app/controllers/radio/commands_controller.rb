class Radio::CommandsController < ApplicationController
  
  authorize_resource :class => Playlist
  
  before_filter :require_radio_running, :except => :connect
  
  def connect
    radio.connect
    flash[:notice] = "Connected!"

    redirect_back_or_default :controller => 'radio/status'
  end
  
  def add
    radio.add @playlist.id
    
    if request.xhr?
      render :partial => 'radio/status/playlist', :locals => {:playlist => @playlist}
    else
      flash[:notice] = "Playlist #{@playlist.name} added!"
      redirect_back_or_default @playlist
    end
  end
  
  def stop
    radio.remove @playlist.id
    
    if request.xhr?
      render :partial => 'radio/status/playlist', :locals => {:playlist => @playlist}
    else
      flash[:notice] = "Playlist #{@playlist.name} removed!"
      redirect_back_or_default @playlist
    end
  end
  
  def next
    radio.next @playlist.id
    
    if request.xhr?
      render :partial => 'radio/status/playlist', :locals => {:playlist => @playlist}
    else
      flash[:notice] = "Next sent."
      redirect_back_or_default @playlist
    end
  end
  
  def disconnect
    radio.disconnect
    flash[:notice] = "Disconnected!"
    
    redirect_back_or_default :controller => 'radio/status'
  end
  
end
