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
    resources :downloads, :only => [:index] do
      get :retry, :on => :collection
      get :remove, :on => :member
      get :try, :on => :collection
    end
    resource :search
  end
  
  # other playlist actions defined below
  resources :playlists, :only => [:index, :create, :new]

  resource :user, :except => [:show] do
    get :search
    get 'adminize/:id' => 'users#adminize', :as => 'adminize'
    get 'activate/:token' => 'activations#activate', :as => 'activate'
    delete ':id' => 'users#destroy', :as => 'user_destroy'
  end
  
  resource :activation, :except => [:destroy]
  get 'activation/form/:user_id' => 'activations#form', :as => 'activation_form'

  resources :password_resets, :only => [:new, :create, :edit, :update]
  get 'logout' => "user_sessions#destroy", :as => 'logout'
  get 'login' => "user_sessions#new", :as => 'login'
  resource :user_session, :only => [:create]

  root :to => 'users#home'
  
  resources :playlists, :except => [:index, :create, :new] do
    resource :pool, :only => [:show] do
      get 'remove/:song_id' => 'pools#remove', :as => 'remove_song'
      get 'add/:song_id' => 'pools#add', :as => 'add_song'
    end
    
    # get 'enqueue/:song_id'
    # resources :queue_items, :path_names => {:new => :enqueue, :destroy => :dequeue} do
    #   get 'enqueue/:song_id' => 'queue_items#new', :on => :collection
    # end
    
    resources :memberships, :only => [:create, :destroy]
    
  end
  
  scope :name_prefix => 'playlist' do 
    post ':playlist_id/enqueue' => 'queue_items#new', :as => 'enqueue'
    get ':playlist_id/enqueue/:song_id' => 'queue_items#new', :as => 'enqueue_song'
    delete ':playlist_id/dequeue/:id' => 'queue_items#destroy', :as => 'dequeue_queue_item'
  end
  
  get ':controller(/:action(/:id(.:format)))'
end
