CohortRadio::Application.routes.draw do |map|
  
  resources :albums, :only => [:update, :index]
  
  resources :artists, :only => [:update, :show, :index] do
    resources :songs, :only => [:index]
  end
  
  get 'artists/:artist_id/:id' => 'albums#show', :as => 'artist_album'
  
  resources :songs do 
    resources :comments
    get :search, :on => :collection
    get :download, :on => :member
  end
  
  namespace :fargo do
    
    resources :downloads, :only => [:index, :destroy] do
      get :retry, :on => :collection
      get :remove, :on => :member
      get :try, :on => :collection
    end
    
    namespace :commands do
      post 'download'
      get 'clear_failed_downloads'
      get 'clear_finished_downloads'
      get 'connect'
      get 'disconnect'
    end
    
    get 'search/results'
    get 'search' => 'search#index'
    
  end
  
  namespace :radio do
    
    namespace :commands do
      get 'connect'
      get 'add/:playlist_id' => 'add', :as => 'add'
      get 'stop/:playlist_id' => 'stop', :as => 'stop'
      get 'next/:playlist_id' => 'next', :as => 'next'
      get 'disconnect'
    end
    
    namespace :status do
      get '' => 'index', :as => ''
    end
    
  end
  
  # other playlist actions defined below
  resources :playlists, :only => [:index, :create, :new]

  resource :user, :except => [:show] do
    get 'search'
    get 'adminize/:id' => 'users#adminize', :as => 'adminize'
    get 'activate/:token' => 'activations#activate', :as => 'activate'
    delete ':id' => 'users#destroy'
  end
  
  resource :activation, :except => [:destroy]
  get 'activation/form/:user_id' => 'activations#form', :as => 'activation_form'

  resources :password_resets, :only => [:new, :create, :edit, :update]
  get 'logout' => "user_sessions#destroy"
  get 'login' => "user_sessions#new"
  resource :user_session, :only => [:create]

  root :to => 'users#home'
  
  resources :playlists, :path => '', :except => [:index, :create, :new] do
    resource :pool, :only => [:show] do
      get 'remove/:song_id' => 'pools#remove', :as => 'remove_song'
      get 'add/:song_id' => 'pools#add', :as => 'add_song'
    end
    
    resources :memberships, :only => [:create, :destroy]
  end
  
  scope :name_prefix => 'playlist' do 
    post ':playlist_id/enqueue' => 'queue_items#new', :as => 'enqueue'
    get ':playlist_id/enqueue/:song_id' => 'queue_items#new', :as => 'enqueue_song'
    delete ':playlist_id/dequeue/:id' => 'queue_items#destroy', :as => 'dequeue_queue_item'
  end
end
