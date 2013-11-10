GoogleDriveVotes::Application.routes.draw do

  resource :auth, :controller => 'auth', :only => [:show] do
    member do
      get :login
    end
  end

  resource :user, :controller => 'user' do
    resources :thrust_votes
  end
  
  root :to => "home#index"
end
