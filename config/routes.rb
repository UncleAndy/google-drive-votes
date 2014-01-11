GoogleDriveVotes::Application.routes.draw do

  mount Resque::Server, :at => "/resque"
  
  resource :auth, :controller => 'auth', :only => [:show] do
    member do
      get :login
    end
  end

  resource :user, :controller => 'user' do
    resources :verify_votes do
      collection do
        get :verify_to
        get :verify_from
      end
    end

    resources :trust_votes do
      collection do
        get :trust_to
        get :trust_from
      end
    end

    resources :property_votes do
      collection do
        get :property_to
        get :property_from
      end
    end
      
    member do
      get :idhash_check
      get :doc_info
      get :idhash_info
      get :auth
    end
  end

  resource :trust_net, :controller => 'trust_net', :only => [:show] do
    member do
      get :members
    end
  end

  resource :synchronize, :only => [:create], :controller => :synchronize

  match '/master', :to => 'master#index'
  
  match 'about', :to => 'home#about'
  match 'extended', :to => 'home#extended'
  root :to => "home#index"
end
