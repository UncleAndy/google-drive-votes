class VerifyVotesController < ApplicationController
  before_filter :check_preauth, :only => [:new, :edit]
  before_filter :login_required
  before_filter :set_user_data
  
  def index
    @user_verify_votes = UserVerifyVote.by_owner(@idhash, @doc_key)
  end

  def show
    redirect_to user_verify_votes_path
  end

  def verify_to
    # Голоса верификации за данного пользователя
    @idhash = params[:idhash] if params[:idhash].present?
    @doc_key = params[:doc_key] if params[:doc_key].present?
    @user_verify_votes = UserVerifyVote.to_user_and_doc(@idhash, @doc_key)
  end

  def verify_from
    # Голоса верификации от данного пользователя (не текущего)
    @idhash = params[:idhash] if params[:idhash].present?
    @doc_key = params[:doc_key] if params[:doc_key].present?
    @user_verify_votes = UserVerifyVote.by_owner(@idhash, @doc_key)
  end
  
  def new
    gon.verify_level = 0
    gon.trust_level = 0
  end
  
  def create
    params[:vote][:vote_idhash] = params[:vote][:vote_idhash].delete(' ')
    params[:vote][:vote_doc_key] = params[:vote][:vote_doc_key].delete(' ')
    if check_data
      # Сначала проверяем что уже нет строки с таким идентификатором пользователя или документа
      founded_idhash = UserVerifyVote.find_by_idhash_and_doc_key_and_vote_idhash(session[:idhash], session[:doc_key], params[:vote][:vote_idhash])
      founded_doc_key = UserVerifyVote.find_by_idhash_and_doc_key_and_vote_doc_key(session[:idhash], session[:doc_key], params[:vote][:vote_doc_key])

      update_required = founded_idhash.present? && founded_doc_key.present? && founded_idhash.id == founded_doc_key.id
      if update_required || founded_doc_key.blank?
        verify_votes = nil
        row_num = 1
        return false if !google_action do
          doc_session = GoogleUserDoc.new(session)
          verify_votes = doc_session.doc_verify_votes_page
          # Находим в документе строку с таким идентификатором и документом или последнюю свободную
          while verify_votes["A#{row_num}"].present? &&
                (verify_votes["A#{row_num}"] != params[:vote][:vote_idhash] || verify_votes["B#{row_num}"] != params[:vote][:vote_doc_key])
            row_num += 1
          end

          verify_votes["A#{row_num}"] = params[:vote][:vote_idhash]
          verify_votes["B#{row_num}"] = params[:vote][:vote_doc_key]
          verify_votes["C#{row_num}"] = params[:vote][:vote_verify_level]
          verify_votes.save
        end
        

        if verify_votes && verify_votes["A#{row_num}"] == params[:vote][:vote_idhash]
          if update_required
            founded_idhash.update_attributes({ :vote_verify_level => params[:vote][:vote_verify_level] })
          else
            UserVerifyVote.create({
                                    :idhash => @idhash,
                                    :doc_key => @doc_key,
                                    :vote_idhash => params[:vote][:vote_idhash],
                                    :vote_doc_key => params[:vote][:vote_doc_key],
                                    :vote_verify_level => params[:vote][:vote_verify_level]
                                    })
          end
        else
          flash[:alert] = I18n.t("errors.google_save_error")
        end
      elsif founded_doc_key
        flash[:alert] = I18n.t("errors.vote_idhash_alredy_present")
      end
    end
    redirect_to user_verify_votes_path
  end

  def edit
    @target_idhash, @target_doc_key = UserVerifyVote.parse_complex_id(params[:id])
    @vote = UserVerifyVote.find_by_idhash_and_vote_idhash_and_vote_doc_key(@idhash, @target_idhash, @target_doc_key)
    if @vote
      gon.verify_level = @vote.vote_verify_level
    else
      flash[:alert] = I18n.t("errors.user_verify_vote_not_found")
      redirect_to :back
    end
  end

  def update
    if check_data(true)
      @target_idhash, @target_doc_key = UserVerifyVote.parse_complex_id(params[:id])

      @vote = UserVerifyVote.find_by_idhash_and_doc_key_and_vote_idhash_and_vote_doc_key(@idhash, @doc_key, @target_idhash, @target_doc_key)
      @vote.update_attributes(params[:vote]) if @vote

      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        verify_votes = doc_session.doc_verify_votes_page
        # Находим строку с данным голосом и прописываем его изменение
        row_num = 1
        while verify_votes["A#{row_num}"].present? && (verify_votes["A#{row_num}"] != @target_idhash || verify_votes["B#{row_num}"] != @target_doc_key)
          row_num += 1
        end

        if verify_votes["A#{row_num}"].present?
          verify_votes["C#{row_num}"] = params[:vote][:vote_verify_level]
          verify_votes.save
        end
      end
    end
    redirect_to user_verify_votes_path
  end

  def destroy
    # Сначала удаляем строку из документа
    @target_idhash, @target_doc_key = UserVerifyVote.parse_complex_id(params[:id])
    @vote = UserVerifyVote.find_by_idhash_and_vote_idhash_and_vote_doc_key(@idhash, @target_idhash, @target_doc_key)
    if @vote
      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        verify_votes = doc_session.doc_verify_votes_page

        # Ищем строку в документе
        row_num = 1
        while verify_votes["A#{row_num}"].present? && (verify_votes["A#{row_num}"] != @target_idhash || verify_votes["B#{row_num}"] != @target_doc_key)
          row_num += 1
        end

        if verify_votes["A#{row_num}"] == @target_idhash && verify_votes["B#{row_num}"] == @target_doc_key
          # Сдвигаем все последующие строки на 1 вверх
          while verify_votes["A#{row_num}"].present?
            verify_votes["A#{row_num}"] = verify_votes["A#{row_num+1}"]
            verify_votes["B#{row_num}"] = verify_votes["B#{row_num+1}"]
            verify_votes["C#{row_num}"] = verify_votes["C#{row_num+1}"]
            verify_votes["D#{row_num}"] = verify_votes["D#{row_num+1}"]
            row_num += 1
          end
          verify_votes.save
        end
      end

      @vote.destroy
      redirect_to user_verify_votes_path
    else
      flash[:alert] = I18n.t("errors.user_verify_vote_not_found")
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
    elsif !without_ids && params[:vote][:vote_doc_key].blank?
      flash[:alert] = I18n.t('errors.doc_key_cannot_be_blank')
      false
    elsif params[:vote][:vote_verify_level] !~ /^(\-|)[0-9]+$/ || !(-10..10).include?(params[:vote][:vote_verify_level].to_i)
      flash[:alert] = I18n.t('errors.verify_level_bad_value')
      false
    else
      true
    end
  end
end
