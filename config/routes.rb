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
      get :add, :as => 'pool' # hack to get naming right
      get :remove, :as => 'pool'
    end
    
    resources :queue_items do 
      post :new, :on => :collection
    end
    
    resources :memberships
  end

  resource :user, :except => [:show] do
    get :search
    match 'adminize/:id' => 'users#adminize', :as => 'adminize'
    match 'activate/:token' => 'activations#activate', :as => 'activate'
  end
  
  resource :activation, :except => [:destroy]
  match 'activation/form/:user_id' => 'activations#form', :as => 'activation_form'

  resources :password_resets, :only => [:new, :create, :edit, :update]
  match 'logout' => "user_sessions#destroy", :as => 'logout'
  match 'login' => "user_sessions#new", :as => 'login'
  resource :user_session, :only => [:create]

  root :to => 'users#home'
  match ':controller(/:action(/:id(.:format)))'
  match ':id' => 'playlists#show', :as => 'playlist'
end
