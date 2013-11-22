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
    if check_data
      # Сначала проверяем что уже нет строки с таким идентификатором пользователя или документа
      founded_idhash = UserTrustNetVote.find_by_idhash_and_vote_idhash(session[:idhash], params[:vote][:vote_idhash])
      founded_doc_key = UserTrustNetVote.find_by_idhash_and_vote_doc_key(session[:idhash], params[:vote][:vote_doc_key])

      if founded_idhash
        flash[:alert] = I18n.t("errors.vote_idhash_alredy_present")
      elsif founded_doc_key
        flash[:alert] = I18n.t("errors.vote_idhash_alredy_present")
      else
        trust_votes = nil
        google_action do
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
        end

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
    if check_data(true)
      @vote = UserTrustNetVote.find_by_vote_idhash(params[:id])
      @vote.update_attributes(params[:vote]) if @vote

      google_action do
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
      end
    end
    redirect_to user_trust_votes_path
  end
  
  private

  def set_user_data
    @idhash = session[:idhash]
    @doc_key = session[:doc_key]
  end

  def check_data(without_ids = false)
    if !without_ids && params[:vote][:vote_idhash] !~ /^[0-9a-fA-F]{64}$/
      flash[:alert] = I18n.t('errors.idhash_bad_format')
      false
    elsif !without_ids && params[:vote][:vote_doc_key].blank?
      flash[:alert] = I18n.t('errors.doc_key_cannot_be_blank')
      false
    elsif params[:vote][:vote_verify_level] !~ /^[0-9]+$/ || !(-10..10).include?(params[:vote][:vote_verify_level].to_i)
      flash[:alert] = I18n.t('errors.verify_level_bad_value')
      false
    elsif params[:vote][:vote_trust_level] !~ /^[0-9]+$/ || !(-10..10).include?(params[:vote][:vote_trust_level].to_i)
      flash[:alert] = I18n.t('errors.trust_level_bad_value')
      false
    else
      true
    end
  end
end
