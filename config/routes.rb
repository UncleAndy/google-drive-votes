GoogleDriveVotes::Application.routes.draw do

  resource :auth, :controller => 'auth', :only => [:show] do
    member do
      get :login
    end
  end

  resource :user, :controller => 'user' do
    resources :trust_votes
    member do
      get :idhash_check
      get :info
    end
  end

  resource :trust_net, :controller => 'trust_net', :only => [:show] do
    member do
      get :members
    end
  end
  
  root :to => "home#index"
end
