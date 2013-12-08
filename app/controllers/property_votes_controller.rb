class PropertyVotesController < ApplicationController
  before_filter :check_preauth, :only => [:new, :edit]
  before_filter :login_required
  before_filter :set_user_data

  def index
    @user_property_votes = UserPropertyVote.by_owner(@idhash, @doc_key)
  end

  def show
    redirect_to user_property_votes_path
  end

  def property_to
    # Голоса заверения свойств за данного пользователя
    @idhash = params[:idhash] if params[:idhash].present?
    @user_property_votes = UserPropertyVote.to_user(@idhash)
  end

  def property_from
    # Голоса заверения свойств от данного пользователя (не текущего)
    @idhash = params[:idhash] if params[:idhash].present?
    @doc_key = params[:doc_key] if params[:doc_key].present?
    @user_property_votes = UserPropertyVote.by_owner(@idhash, @doc_key)
  end

  def new
    gon.property_level = 0
  end

  def create
    params[:vote][:vote_idhash] = params[:vote][:vote_idhash].delete(' ')
    if check_data
      # Сначала проверяем что уже нет строки с таким идентификатором пользователя
      property_votes = nil
      row_num = 1
      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        property_votes = doc_session.doc_property_votes_page
        # Находим в документе строку с таким идентификатором и свойством или последнюю свободную
        while property_votes["A#{row_num}"].present? &&
              (property_votes["A#{row_num}"] != params[:vote][:vote_idhash] || property_votes["B#{row_num}"] != params[:vote][:vote_property_key])
          row_num += 1
        end

        property_votes["A#{row_num}"] = params[:vote][:vote_idhash]
        property_votes["B#{row_num}"] = params[:vote][:vote_property_key]
        property_votes["C#{row_num}"] = params[:vote][:vote_property_level]
        property_votes.save
      end


      if property_votes &&
         property_votes["A#{row_num}"] == params[:vote][:vote_idhash] && property_votes["B#{row_num}"] == params[:vote][:vote_property_key]
        founded_idhash = UserPropertyVote.find_by_idhash_and_doc_key_and_vote_idhash_and_vote_property_key(session[:idhash], session[:doc_key], params[:vote][:vote_idhash], params[:vote][:vote_property_key])
        if founded_idhash.present?
          founded_idhash.update_attributes({ :vote_property_level => params[:vote][:vote_property_level] })
        else
          UserPropertyVote.create({
                                  :idhash => @idhash,
                                  :doc_key => @doc_key,
                                  :vote_idhash => params[:vote][:vote_idhash],
                                  :vote_property_key => params[:vote][:vote_property_key],
                                  :vote_property_level => params[:vote][:vote_property_level]
                                  })
        end
      else
        flash[:alert] = I18n.t("errors.google_save_error")
      end
    end
    redirect_to user_property_votes_path
  end


  def edit
    @id = params[:id]
    @vote = UserPropertyVote.find_by_id(@id)
    if @vote
      gon.property_level = @vote.vote_property_level
    else
      flash[:alert] = I18n.t("errors.user_property_vote_not_found")
      redirect_to :back
    end
  end


  def update
    if check_data(true)
      @id = params[:id]
      @vote = UserPropertyVote.find_by_id(@id)
      @vote.update_attributes(:vote_property_level => params[:vote][:vote_property_level]) if @vote
      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        property_votes = doc_session.doc_property_votes_page
        # Находим строку с данным голосом и прописываем его изменение
        row_num = 1
        while property_votes["A#{row_num}"].present? &&
              (property_votes["A#{row_num}"] != @vote.vote_idhash || property_votes["B#{row_num}"] != @vote.vote_property_key)
          row_num += 1
        end

        if property_votes["A#{row_num}"].present?
          property_votes["C#{row_num}"] = params[:vote][:vote_property_level]
          property_votes.save
        end
      end
    end
    redirect_to user_property_votes_path
  end

  def destroy
    # Сначала удаляем строку из документа
    @id = params[:id]
    @vote = UserPropertyVote.find_by_id(@id)
    if @vote
      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        property_votes = doc_session.doc_property_votes_page

        # Ищем строку в документе
        row_num = 1
        while property_votes["A#{row_num}"].present? &&
              (property_votes["A#{row_num}"] != @vote.vote_idhash || property_votes["B#{row_num}"] != @vote.vote_property_key)
          row_num += 1
        end
        
        if property_votes["A#{row_num}"] == @vote.vote_idhash
          # Сдвигаем все последующие строки на 1 вверх
          while property_votes["A#{row_num}"].present?
            property_votes["A#{row_num}"] = property_votes["A#{row_num+1}"]
            property_votes["B#{row_num}"] = property_votes["B#{row_num+1}"]
            property_votes["C#{row_num}"] = property_votes["C#{row_num+1}"]
            row_num += 1
          end
          property_votes.save
        end
      end

      @vote.destroy
      redirect_to user_property_votes_path
    else
      flash[:alert] = I18n.t("errors.user_property_vote_not_found")
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
    elsif params[:vote][:vote_property_level] !~ /^(\-|)[0-9]+$/ || !(-10..10).include?(params[:vote][:vote_property_level].to_i)
      flash[:alert] = I18n.t('errors.property_level_bad_value')
      false
    else
      true
    end
  end
  
end
