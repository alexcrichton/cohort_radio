CohortRadio::Application.routes.draw do |map|
  
  resources :songs do 
    get :search, :on => :collection
    get :download, :on => :member
  end
  
  namespace :fargo do
    resources :downloads do
      get :retry, :on => :member
    end
    resource :search
  end

  resources :playlists do
    post :enqueue, :on => :member
  end

  resource :user, :except => [:show, :destroy] do
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
  match ':id' => 'playlists#show'
end
