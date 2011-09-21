require 'resque/server'
require 'resque/status_server'

CohortRadio::Application.routes.draw do
  devise_for :users
  mount Resque::Server => 'resque'

  resources :artists, :only => [:show, :update, :edit, :index] do
    resources :songs, :only => [:index]
    resources :albums, :path => '', :only => [:show, :update, :edit]
  end

  get 'albums' => 'albums#index'

  resources :songs do
    get :search, :on => :collection
  end

  get 'fargo/search'
  post 'pusher/auth' => 'users#pusher_auth'

  # other playlist actions defined below
  resources :playlists, :only => [:index, :create, :new]

  get 'users/search'

  get 'cache.manifest' => lambda{ |env|
    opts = Rails.env.production? ? {} : {:cache_interval => 1}
    @offline ||= Rack::Offline.configure(opts) do
      env = Rails.application.assets
      digest = Rails.application.config.assets.digest
      ['mobile.js', 'mobile.css', 'fargo/search.js',
       'fargo/mobile_search.css', 'ajax-small.gif'].each do |asset|
        if digest
          cache '/assets/' + env[asset].digest_path
        else
          cache '/assets/' + env[asset].logical_path
        end
      end
      network '/'
    end
    @offline.call env
  }
  root :to => 'playlists#index'

  resources :playlists, :path => '', :except => [:index, :create, :new] do
    resource :pool, :only => [:show] do
      get 'remove/:song_id' => 'pools#remove', :as => 'remove_song'
      get 'add/:song_id' => 'pools#add', :as => 'add_song'
    end

    get :queue, :on => :member
  end

  scope :as => 'playlist' do
    post ':playlist_id/enqueue' => 'queue_items#create', :as => 'enqueue'
    get ':playlist_id/enqueue/:song_id' => 'queue_items#create', :as => 'enqueue_song'
    delete ':playlist_id/dequeue/:id' => 'queue_items#destroy', :as => 'dequeue_queue_item'
  end
end
