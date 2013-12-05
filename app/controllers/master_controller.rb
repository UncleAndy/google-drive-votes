class MasterController < ApplicationController
  before_filter :login_required
  before_filter :check_preauth, :only => [:index]
  
  def index
    
  end
end
