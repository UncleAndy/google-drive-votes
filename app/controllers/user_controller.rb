class UserController < ApplicationController
  before_filter :login_required
  before_filter :user_doc_prepare, :only => [:show, :create]
  
  def show
    if @user_idhash.blank?
      redirect_to new_user_path
    end
  end

  def new
  end

  def create
    idhash = params[:user][:idhash]
    if idhash.present?
      @user_info["B1"] = idhash
      @user_info.save
    end
    redirect_to user_path
  end

  private

  def user_doc_prepare
    # Создаем основной документ пользователя
    doc_created = false
    @user_doc = user_session.spreadsheet_by_title(Settings.google.user.main_doc)
    if !@user_doc
      @collection = user_session.collection_by_title(Settings.google.user.collection)
      if !@collection
        @collection = user_session.root_collection.create_subcollection(Settings.google.user.collection)
      end
      
      doc_created = true
      @user_doc = user_session.create_spreadsheet(Settings.google.user.main_doc)
      @collection.add(@user_doc)
    end
    @user_doc.acl.push({:scope_type => "default", :role => "reader"}) if doc_created
    
    # Смотрим наличие идентификационного хэша и перенеправляем на new если его нет
    @user_info = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info)
    if !@user_info
      if doc_created
        @user_info = @user_doc.worksheets()[0]
        @user_info.title = Settings.google.user.main_doc_pages.user_info
        @user_info.max_rows = 1000
        @user_info.max_cols = 3
      else
        @user_info = @user_doc.add_worksheet(Settings.google.user.main_doc_pages.user_info, 1000, 3)
      end
      @user_info["A1"] = I18n.t('user_info.idhash')
      @user_info["A2"] = I18n.t('user_info.trust_net_strnum')
      @user_info.save
    end
    @user_idhash = @user_info["B1"] if @user_info

    # Страница голосов в сети доверия
    @user_trust_votes = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_net)
    @user_trust_votes = @user_doc.add_worksheet(Settings.google.user.main_doc_pages.trust_net, 1000, 3) if !@user_trust_votes

    # Страница голосов в голосованиях
    @user_votes = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.votes)
    @user_votes = @user_doc.add_worksheet(Settings.google.user.main_doc_pages.votes, 10000, 2) if !@user_votes
  end
end
