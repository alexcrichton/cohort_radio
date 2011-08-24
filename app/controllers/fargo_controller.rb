class FargoController < ApplicationController

  authorize_resource :class => Fargo
  before_filter :require_fargo_connected

  def search
    @channel = params[:channel] || SecureRandom.hex(10)
    if params[:q].present?
      Resque.push :search, :args => [params[:q], @channel]
    end

    respond_to do |format|
      format.html
      format.js { render :nothing => true }
    end
  end

  def download
    Resque.push :downloads, :args => [params[:nick], params[:file],
                                      params[:tth], params[:size]]
    respond_to do |format|
      format.js { render :nothing => true }
    end
  end

end
