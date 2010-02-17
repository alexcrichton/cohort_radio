class Fargo::SearchController < ApplicationController
  
  before_filter { |c| c.unauthorized! if c.cannot? :search, Fargo }
    
  def index
    if params[:q]
      params[:q] = "#{params[:q]} mp3" unless params[:q].index 'mp3'
      search = Fargo::Search.new(:query => params[:q], :filetype => Fargo::Search::AUDIO)
      
      fargo.search_hub search
      sleep 2
      @results = fargo.search_results search

      @result_map = Hash.new{ |h, k| h[k] = [] }
      @results.each { |result| @result_map[result[:nick]] << result }
    end
  end
    
end
