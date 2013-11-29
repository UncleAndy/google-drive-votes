GoogleDriveVotes::Application.routes.draw do

  resource :auth, :controller => 'auth', :only => [:show] do
    member do
      get :login
    end
  end

  resource :user, :controller => 'user' do
    resources :trust_votes do
      collection do
        get :trust_to
        get :trust_from
        get :verify_to
        get :verify_from
      end
    end
    member do
      get :idhash_check
      get :doc_info
      get :idhash_info
    end
  end

  resource :trust_net, :controller => 'trust_net', :only => [:show] do
    member do
      get :members
    end
  end

  match 'about', :to => 'home#about'
  match 'extended', :to => 'home#extended'
  root :to => "home#index"
end
