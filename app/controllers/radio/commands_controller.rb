class Radio::CommandsController < ApplicationController
  
  before_filter { |c| c.unauthorized! if c.cannot? :manage, Radio }
  
  def connect
    radio.connect
    flash[:notice] = "Connected!"

    redirect_to playlist_path('main')
  end
  
  def disconnect
    radio.disconnect
    flash[:notice] = "Disconnected!"
    
    redirect_to playlist_path('main')
  end
  
end
