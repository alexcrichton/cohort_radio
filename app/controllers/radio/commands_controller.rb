class Radio::CommandsController < ApplicationController

  load_and_authorize_resource :playlist, :find_by => :slug

  before_filter :require_radio_running, :except => :connect
  respond_to :js
  respond_to :html, :only => [:connect, :disconnect]

  def connect
    radio.connect
    flash[:notice] = 'Connected!'

    redirect_back_or_default :controller => 'radio/status'
  end

  def add
    radio.add @playlist.id

    respond_with @playlist do |format|
      format.html { redirect_to @playlist }
      format.js   { render 'replace_row' }
    end
  end

  def stop
    radio.remove @playlist.id

    respond_with @playlist do |format|
      format.js { render 'replace_row' }
    end
  end

  def next
    radio.next @playlist.id

    respond_with @playlist do |format|
      format.js { render 'replace_row' }
    end
  end

  def disconnect
    radio.disconnect
    flash[:notice] = "Disconnected!"

    redirect_back_or_default :controller => 'radio/status'
  end

end
