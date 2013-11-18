class TrustNetController < ApplicationController
  before_filter :set_sort, :only => [:show]
  
  def show
    if @sort == 'verify'
      @results = @trust_net_results.rows.sort { |x,y| y[2].to_f <=> x[2].to_f }
    elsif @sort == 'verify_desc'
      @results = @trust_net_results.rows.sort { |x,y| x[2].to_f <=> y[2].to_f }
    elsif @sort == 'trust'
      @results = @trust_net_results.rows.sort { |x,y| y[3].to_f <=> x[3].to_f }
    elsif @sort == 'trust_desc'
      @results = @trust_net_results.rows.sort { |x,y| x[3].to_f <=> y[3].to_f }
    elsif @sort == 'count'
      @results = @trust_net_results.rows.sort { |x,y| y[4].to_f <=> x[4].to_f }
    elsif @sort == 'count_desc'
      @results = @trust_net_results.rows.sort { |x,y| x[4].to_f <=> y[4].to_f }
    else
      @results = @trust_net_results.rows.sort { |x,y| y[2].to_f <=> x[2].to_f }
    end
    
    respond_to do |format|
      format.html
      format.xml { render :xml => @trust_net_results.rows.to_xml }
      format.js { render :json => @trust_net_results.rows.to_json }
      format.json { render :json => @trust_net_results.rows.to_json }
    end
  end

  def members
    @members = @trust_net_members.rows
    
    respond_to do |format|
      format.html
    end
  end
  
  private

  def set_sort
    @sort = 'verify'
    @sort = params[:sort] if params[:sort].present?
  end
end
