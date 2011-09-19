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

  get 'uploads/:file' => 'songs#download_user_upload',
      :as => :download_user_upload

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
