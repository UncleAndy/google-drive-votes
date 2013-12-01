class TrustNetController < ApplicationController
  before_filter :set_sort, :only => [:show]
  
  def show
    if @sort == 'verify'
      @results = TrustNetResult.order('verify_level desc')
    elsif @sort == 'verify_desc'
      @results = TrustNetResult.order('verify_level')
    elsif @sort == 'trust'
      @results = TrustNetResult.order('trust_level desc')
    elsif @sort == 'trust_desc'
      @results = TrustNetResult.order('trust_level')
    elsif @sort == 'count'
      @results = TrustNetResult.order('votes_count desc')
    elsif @sort == 'count_desc'
      @results = TrustNetResult.order('votes_count')
    else
      @results = TrustNetResult.order('verify_level desc')
    end

    @last_time_calculate = '-'
    ltc = TrustNetResultHistory.maximum(:result_time)
    @last_time_calculate = ltc.localtime.strftime("%F %T") if ltc.present?
    
    respond_to do |format|
      format.html
      format.xml { render :xml => @results.to_xml }
      format.js { render :json => @results.to_json }
      format.json { render :json => @results.to_json }
    end
  end

  def members
    @members = TrustNetMember.all
    
    respond_to do |format|
      format.html
      format.xml { render :xml => @members.to_xml }
      format.js { render :json => @members.to_json }
      format.json { render :json => @members.to_json }
    end
  end
  
  private

  def set_sort
    @sort = 'verify'
    @sort = params[:sort] if params[:sort].present?
  end
end
