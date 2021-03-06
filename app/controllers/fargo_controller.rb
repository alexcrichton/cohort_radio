class FargoController < ApplicationController

  def search
    @channel = params[:channel] || SecureRandom.hex(10)
    if params[:q].present?
      Resque.enqueue FargoSearch, params[:q], @channel
    end

    respond_to do |format|
      format.html
    end
  end

end
