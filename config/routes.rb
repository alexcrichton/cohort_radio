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

  resources :playlists do
    resource :pool do
      match 'remove/:song_id' => 'pools#remove', :as => 'pool_remove_song'
      match 'add/:song_id' => 'pools#add', :as => 'pool_add_song'
    end
    
    resources :queue_items, :path_names => {:new => :enqueue, :destroy => :dequeue} do
      match 'enqueue/:song_id' => 'queue_items#new', :on => :collection
    end
    
    resources :memberships
  end
  

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
  
  match ':controller(/:action(/:id(.:format)))'
  
  # Shorter routes than above are defined down here
  match ':id' => 'playlists#show', :as => 'playlist', :conditions => {:method => :get}
  
  match ':playlist_id/enqueue' => 'queue_items#new', :as => 'playlist_enqueue'
  match ':playlist_id/enqueue/:song_id' => 'queue_items#new', :as => 'playlist_enqueue_song'
  match ':playlist_id/dequeue/:id' => 'queue_items#destroy', :as => 'playlist_dequeue_queue_item'
  
end
