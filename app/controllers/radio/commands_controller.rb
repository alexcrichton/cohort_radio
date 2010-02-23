class Radio::CommandsController < ApplicationController
  
  before_filter { |c| c.unauthorized! if c.cannot? :manage, Radio }
  
  before_filter :require_radio_running, :except => :connect
  
  def connect
    radio.connect
    flash[:notice] = "Connected!"

    redirect_to :controller => 'radio/status'
  end
  
  def add
    radio.add @playlist
    
    if request.xhr?
      render :partial => 'radio/status/playlist', :locals => {:playlist => @playlist}
    else
      flash[:notice] = "Playlist #{@playlist.name} added!"
      redirect_to @playlist
    end
  end
  
  def stop
    radio.remove @playlist
    
    if request.xhr?
      render :partial => 'radio/status/playlist', :locals => {:playlist => @playlist}
    else
      flash[:notice] = "Playlist #{@playlist.name} removed!"
      redirect_to @playlist
    end
  end
  
  def next
    radio.next @playlist
    
    if request.xhr?
      render :partial => 'radio/status/playlist', :locals => {:playlist => @playlist}
    else
      flash[:notice] = "Next sent."
      redirect_to @playlist
    end
  end
  
  def disconnect
    radio.disconnect
    flash[:notice] = "Disconnected!"
    
    redirect_to :controller => 'radio/status'
  end
  
end
