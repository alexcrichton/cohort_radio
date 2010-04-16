CohortRadio::Application.routes.draw do |map|
  
  resources :albums, :only => [:update, :index]
  
  resources :artists, :only => [:update, :show, :index] do
    resources :songs, :only => [:index]
  end
  
  match 'artists/:artist_id/:id' => 'albums#show', :as => 'artist_album'
  
  resources :songs do 
    resources :comments
    get :search, :on => :collection
    get :download, :on => :member
  end
  
  namespace :fargo do
    resources :downloads do
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
    match 'adminize/:id' => 'users#adminize', :as => 'adminize'
    match 'activate/:token' => 'activations#activate', :as => 'activate'
    match ':id' => 'users#destroy', :conditions => {:method => :delete}, :as => 'user_destroy'
  end
  
  resource :activation, :except => [:destroy]
  match 'activation/form/:user_id' => 'activations#form', :as => 'activation_form'

  resources :password_resets, :only => [:new, :create, :edit, :update]
  match 'logout' => "user_sessions#destroy", :as => 'logout'
  match 'login' => "user_sessions#new", :as => 'login'
  resource :user_session, :only => [:create]

  root :to => 'users#home'
  
  
  resources :playlists, :except => [:index, :create, :new] do
    resource :pool do
      match 'remove/:song_id' => 'pools#remove', :as => 'remove_song'
      match 'add/:song_id' => 'pools#add', :as => 'add_song'
    end
    
    resources :queue_items, :path_names => {:new => :enqueue, :destroy => :dequeue} do
      match 'enqueue/:song_id' => 'queue_items#new', :on => :collection
    end
    
    resources :memberships
    
  end
  
  scope :name_prefix => 'playlist' do 
    match ':playlist_id/enqueue' => 'queue_items#new', :as => 'enqueue'
    match ':playlist_id/enqueue/:song_id' => 'queue_items#new', :as => 'enqueue_song'
    match ':playlist_id/dequeue/:id' => 'queue_items#destroy', :as => 'dequeue_queue_item'
  end
  match ':controller(/:action(/:id(.:format)))'
  
end
