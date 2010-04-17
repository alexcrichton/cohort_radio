class Fargo::SearchController < ApplicationController
  
  before_filter { |c| c.authorize! :search, Fargo }
  before_filter :set_search
  
  before_filter :require_fargo_connected
    
  def index
    fargo.search @search if @search
  end
  
  def results
    @results = fargo.search_results(@search) || []

    @result_map = Hash.new{ |h, k| h[k] = [] }
    @results.each { |result| @result_map[result[:nick]] << result }
  end
  
  private
  def set_search
    return true unless params[:q]
    params[:q] = "#{params[:q]} mp3" unless params[:q].index 'mp3'
    @search = Fargo::Search.new(:query => params[:q], :filetype => Fargo::Search::AUDIO)
  end
    
end
