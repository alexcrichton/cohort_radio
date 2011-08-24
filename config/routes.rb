require 'resque/server'
require 'resque/status_server'

CohortRadio::Application.routes.draw do
  devise_for :users
  mount Resque::Server => 'resque'

  resources :albums

  resources :artists do
    resources :songs, :only => [:index]
  end

  get 'artists/:artist_id/:id' => 'albums#show', :as => 'artist_album'

  resources :songs do
    get :search, :on => :collection
    put :rate, :on => :member
  end

  get 'fargo/search'
  post 'fargo/download'

  namespace :radio do

    get 'commands/connect'
    get 'commands/add/:playlist_id'  => 'commands#add',  :as => 'add'
    get 'commands/stop/:playlist_id' => 'commands#stop', :as => 'stop'
    get 'commands/next/:playlist_id' => 'commands#next', :as => 'next'
    get 'commands/disconnect'

    get 'status' => 'status#index'
  end

  # other playlist actions defined below
  resources :playlists, :only => [:index, :create, :new]

  get 'users/search'

  root :to => 'playlists#index'

  resources :playlists, :path => '', :except => [:index, :create, :new] do
    resource :pool, :only => [:show] do
      get 'remove/:song_id' => 'pools#remove', :as => 'remove_song'
      get 'add/:song_id' => 'pools#add', :as => 'add_song'
    end

    resources :memberships, :only => [:create, :destroy]

    member do
      get :queue
    end
  end

  scope :as => 'playlist' do
    post ':playlist_id/enqueue' => 'queue_items#create', :as => 'enqueue'
    get ':playlist_id/enqueue/:song_id' => 'queue_items#create', :as => 'enqueue_song'
    delete ':playlist_id/dequeue/:id' => 'queue_items#destroy', :as => 'dequeue_queue_item'
  end
end
