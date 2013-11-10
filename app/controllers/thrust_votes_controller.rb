class ThrustVotesController < ApplicationController
  before_filter :set_user_doc
  before_filter :set_thrust_vote, :exclude => [:index, :new, :create]

  def index
    
  end
  
  private

  def set_user_doc
    @user_doc = user_session.spreadsheet_by_title(Settings.google.user.main_doc)
    @user_trust_votes = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_net)
  end
  
  def set_thrust_vote
    idhash = params[:id]

    return if idhash.blank?
    
    @user_trust_votes.rows.each do |row|
      if idhash == row[0]
        @thrust_vote = { :idhash => idhash, :verify_index => row[1].to_f, :thrust_index => row[2].to_f }
        break
      elsif row[0].blank?
        break
      end
    end
  end
end
