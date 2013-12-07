class TrustVotesController < ApplicationController
  before_filter :check_preauth, :only => [:new, :edit]
  before_filter :login_required
  before_filter :set_user_data
  
  def index
    @user_trust_votes = UserTrustVote.by_owner(@idhash, @doc_key)
  end

  def show
    redirect_to user_trust_votes_path
  end

  def trust_to
    # Голоса доверия за данного пользователя
    @idhash = params[:idhash] if params[:idhash].present?
    @user_trust_votes = UserTrustVote.to_user(@idhash)
  end

  def trust_from
    # Голоса доверия от данного пользователя (не текущего)
    @idhash = params[:idhash] if params[:idhash].present?
    @doc_key = params[:doc_key] if params[:doc_key].present?
    @user_trust_votes = UserTrustVote.by_owner(@idhash, @doc_key)
  end
  
  def new
    gon.verify_level = 0
    gon.trust_level = 0
  end
  
  def create
    params[:vote][:vote_idhash] = params[:vote][:vote_idhash].delete(' ')
    if check_data
      # Сначала проверяем что уже нет строки с таким идентификатором пользователя
      trust_votes = nil
      row_num = 1
      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        trust_votes = doc_session.doc_trust_votes_page
        # Находим в документе строку с таким идентификатором и документом или последнюю свободную
        while trust_votes["A#{row_num}"].present? && trust_votes["A#{row_num}"] != params[:vote][:vote_idhash]
          row_num += 1
        end

        trust_votes["A#{row_num}"] = params[:vote][:vote_idhash]
        trust_votes["B#{row_num}"] = params[:vote][:vote_trust_level]
        trust_votes.save
      end


      if trust_votes && trust_votes["A#{row_num}"] == params[:vote][:vote_idhash]
        founded_idhash = UserTrustVote.find_by_idhash_and_doc_key_and_vote_idhash(session[:idhash], session[:doc_key], params[:vote][:vote_idhash])
        if founded_idhash.present?
          founded_idhash.update_attributes({ :vote_trust_level => params[:vote][:vote_trust_level] })
        else
          UserTrustVote.create({
                                  :idhash => @idhash,
                                  :doc_key => @doc_key,
                                  :vote_idhash => params[:vote][:vote_idhash],
                                  :vote_trust_level => params[:vote][:vote_trust_level]
                                  })
        end
      else
        flash[:alert] = I18n.t("errors.google_save_error")
      end
    end
    redirect_to user_trust_votes_path
  end

  def edit
    @target_idhash = params[:id]
    @vote = UserTrustVote.find_by_idhash_and_doc_key_and_vote_idhash(@idhash, @doc_key, @target_idhash)
    if @vote
      gon.trust_level = @vote.vote_trust_level
    else
      flash[:alert] = I18n.t("errors.user_trust_vote_not_found")
      redirect_to :back
    end
  end

  def update
    if check_data(true)
      @target_idhash = params[:id]
      @vote = UserTrustVote.find_by_idhash_and_doc_key_and_vote_idhash(@idhash, @doc_key, @target_idhash)
      @vote.update_attributes(params[:vote]) if @vote

      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        trust_votes = doc_session.doc_trust_votes_page
        # Находим строку с данным голосом и прописываем его изменение
        row_num = 1
        while trust_votes["A#{row_num}"].present? && trust_votes["A#{row_num}"] != @target_idhash
          row_num += 1
        end

        if trust_votes["A#{row_num}"].present?
          trust_votes["B#{row_num}"] = params[:vote][:vote_trust_level]
          trust_votes.save
        end
      end
    end
    redirect_to user_trust_votes_path
  end

  def destroy
    # Сначала удаляем строку из документа
    @target_idhash = params[:id]
    @vote = UserTrustVote.find_by_idhash_and_doc_key_and_vote_idhash(@idhash, @doc_key, @target_idhash)
    if @vote
      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        trust_votes = doc_session.doc_trust_votes_page

        # Ищем строку в документе
        row_num = 1
        while trust_votes["A#{row_num}"].present? && trust_votes["A#{row_num}"] != @target_idhash
          row_num += 1
        end

        if trust_votes["A#{row_num}"] == @target_idhash
          # Сдвигаем все последующие строки на 1 вверх
          while trust_votes["A#{row_num}"].present?
            trust_votes["A#{row_num}"] = trust_votes["A#{row_num+1}"]
            trust_votes["B#{row_num}"] = trust_votes["B#{row_num+1}"]
            trust_votes["C#{row_num}"] = trust_votes["C#{row_num+1}"]
            trust_votes["D#{row_num}"] = trust_votes["D#{row_num+1}"]
            row_num += 1
          end
          trust_votes.save
        end
      end

      @vote.destroy
      redirect_to user_trust_votes_path
    else
      flash[:alert] = I18n.t("errors.user_trust_vote_not_found")
      redirect_to :back
    end
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
    elsif params[:vote][:vote_trust_level] !~ /^(\-|)[0-9]+$/ || !(-10..10).include?(params[:vote][:vote_trust_level].to_i)
      flash[:alert] = I18n.t('errors.trust_level_bad_value')
      false
    else
      true
    end
  end
end
