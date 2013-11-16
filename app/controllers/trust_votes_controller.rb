class TrustVotesController < ApplicationController
  before_filter :set_user_doc
  before_filter :set_trust_vote, :exclude => [:index, :new, :create]

  def index
  end

  def new
    gon.verify_level = 0
    gon.trust_level = 0
  end
  
  def create
    # Сначала проверяем что уже нет строки с таким идентиикатором пользователя или документа
    founded_idhash = false
    founded_doc_key = false
    row_num = 1
    @user_trust_votes.rows.each do |row|
      if row[0] == params[:vote][:idhash]
        founded_idhash = true
        break
      end
      if row[1] == params[:vote][:doc_key]
        founded_doc_key = true
        break
      end
      if row[0].blank?
        break
      end
      row_num += 1
    end

    if founded_idhash
      flash[:alert] = I18n.t("errors.vote_idhash_alredy_present")
    elsif founded_doc_key
      flash[:alert] = I18n.t("errors.vote_idhash_alredy_present")
    else
      @user_trust_votes["A#{row_num}"] = params[:vote][:idhash]
      @user_trust_votes["B#{row_num}"] = params[:vote][:doc_key]
      @user_trust_votes["C#{row_num}"] = params[:vote][:verify_level]
      @user_trust_votes["D#{row_num}"] = params[:vote][:trust_level]
      @user_trust_votes.save
    end
    redirect_to user_trust_votes_path
  end

  def edit
    gon.verify_level = @trust_vote[:verify_level]
    gon.trust_level = @trust_vote[:trust_level]
    @vote = OpenStruct.new
    @vote.idhash = @trust_vote[:idhash]
    @vote.doc_key = @trust_vote[:doc_key]
  end

  def update
    @user_trust_votes["C#{@trust_vote_row_num}"] = params[:vote][:verify_level]
    @user_trust_votes["D#{@trust_vote_row_num}"] = params[:vote][:trust_level]
    @user_trust_votes.save
    redirect_to user_trust_votes_path
  end
  
  private

  def set_user_doc
    @user_doc = user_session.spreadsheet_by_title(Settings.google.user.main_doc)
    @user_trust_votes = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_net)
  end
  
  def set_trust_vote
    idhash = params[:id]

    return if idhash.blank?

    @trust_vote_row_num = 1
    @user_trust_votes.rows.each do |row|
      if idhash == row[0]
        @trust_vote = { :idhash => idhash, :doc_key => row[1], :verify_level => row[2].to_f, :trust_level => row[3].to_f }
        break
      elsif row[0].blank?
        break
      end
      @trust_vote_row_num += 1
    end
  end
end
