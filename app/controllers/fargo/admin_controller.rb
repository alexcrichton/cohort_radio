class Fargo::AdminController < ApplicationController
  
  def index
    @connected = fargo 'connected?'
  end
  
  def log
    lines = params[:lines] || 120

    @lines = File.new("#{Rails.root}/log/fargo.output").readlines.reverse[0..lines].reverse
  end
  
end
