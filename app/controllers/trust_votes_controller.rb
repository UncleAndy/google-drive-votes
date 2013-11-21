class TrustVotesController < ApplicationController
  before_filter :login_required
  before_filter :set_user_data
  
  def index
    @user_trust_votes = UserTrustNetVote.by_owner(@idhash)
  end

  def new
    gon.verify_level = 0
    gon.trust_level = 0
  end
  
  def create
    # Сначала проверяем что уже нет строки с таким идентиикатором пользователя или документа
    founded_idhash = UserTrustNetVote.find_by_vote_idhash(params[:vote][:idhash])
    founded_doc_key = UserTrustNetVote.find_by_vote_doc_key(params[:vote][:doc_key])

    if founded_idhash
      flash[:alert] = I18n.t("errors.vote_idhash_alredy_present")
    elsif founded_doc_key
      flash[:alert] = I18n.t("errors.vote_idhash_alredy_present")
    else
      GoogleUserDoc.init(session)
      trust_votes = GoogleUserDoc.doc_trust_votes_page
      # Находим последнюю свободную строку в документе и в нее прописываем новый голос
      row_num = 1
      while trust_votes["A#{row_num}"].present?
        row_num += 1
      end

      trust_votes["A#{row_num}"] = params[:vote][:vote_idhash]
      trust_votes["B#{row_num}"] = params[:vote][:vote_doc_key]
      trust_votes["C#{row_num}"] = params[:vote][:vote_verify_level]
      trust_votes["D#{row_num}"] = params[:vote][:vote_trust_level]
      trust_votes.save

      if trust_votes["A#{row_num}"] == params[:vote][:vote_idhash]
        UserTrustNetVote.create({
                                :idhash => @idhash,
                                :vote_idhash => params[:vote][:vote_idhash],
                                :vote_doc_key => params[:vote][:vote_doc_key],
                                :vote_verify_level => params[:vote][:vote_verify_level],
                                :vote_trust_level => params[:vote][:vote_trust_level]
                                })
      else
        flash[:alert] = I18n.t("errors.google_save_error")
      end
    end
    redirect_to user_trust_votes_path
  end

  def edit
    @vote = UserTrustNetVote.find_by_vote_idhash(params[:id])
    if @vote
      gon.verify_level = @vote.vote_verify_level
      gon.trust_level = @vote.vote_trust_level
    else
      flash[:alert] = I18n.t("errors.user_trust_vote_not_found")
      redirect_to :back
    end
  end

  def update
    @vote = UserTrustNetVote.find_by_vote_idhash(params[:id])
    @vote.update_attributes(params[:vote]) if @vote

    GoogleUserDoc.init(session)
    trust_votes = GoogleUserDoc.doc_trust_votes_page
    # Находим строку с данным голосом и прописываем его изменение
    row_num = 1
    while trust_votes["A#{row_num}"].present? &&
          trust_votes["A#{row_num}"] != params[:id]
      row_num += 1
    end

    if trust_votes["A#{row_num}"].present?
      trust_votes["C#{row_num}"] = params[:vote][:vote_verify_level]
      trust_votes["D#{row_num}"] = params[:vote][:vote_trust_level]
      trust_votes.save
    end

    redirect_to user_trust_votes_path
  end
  
  private

  def set_user_data
    @idhash = session[:idhash]
    @doc_key = session[:doc_key]
  end
end
