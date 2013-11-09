GoogleDriveVotes::Application.routes.draw do

  resource :auth, :controller => 'auth', :only => [:show] do
    member do
      get :login
    end
  end

  resource :user, :controller => 'user'
  
  root :to => "home#index"
end
