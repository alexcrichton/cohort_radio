class Fargo::CommandsController < ApplicationController

  authorize_resource :class => Fargo

  before_filter :require_fargo_connected, :except => :connect
  # respond_to :js
  #
  # def connect
  #   fargo.connect
  #
  #   redirect_back_or_default playlists_path, :notice => "Connected!"
  # end
  #
  # def disconnect
  #   fargo.disconnect
  #
  #   redirect_back_or_default playlists_path, :notice => "Disconnected!"
  # end

end
