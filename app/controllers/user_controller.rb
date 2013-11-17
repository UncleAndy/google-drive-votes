class UserController < ApplicationController
  before_filter :login_required
  before_filter :user_doc_prepare, :only => [:show, :create, :update]
  before_filter :set_user_by_id, :only => [:info]
  
  def show
    if @user_idhash.blank?
      redirect_to new_user_path
    end
    @user = OpenStruct.new
    @user.emails = @user_info["B3"]
    @user.skype = @user_info["B4"]
    @user.icq = @user_info["B5"]
    @user.jabber = @user_info["B6"]
    @user.phones = @user_info["B7"]
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

  def update
    @user_info["A3"] = I18n.t("simple_form.labels.defaults.emails")
    @user_info["B3"] = params[:user][:emails]
    @user_info["A4"] = I18n.t("simple_form.labels.defaults.skype")
    @user_info["B4"] = params[:user][:skype]
    @user_info["A5"] = I18n.t("simple_form.labels.defaults.icq")
    @user_info["B5"] = params[:user][:icq]
    @user_info["A6"] = I18n.t("simple_form.labels.defaults.jabber")
    @user_info["B6"] = params[:user][:jabber]
    @user_info["A7"] = I18n.t("simple_form.labels.defaults.phones")
    @user_info["B7"] = params[:user][:phones]
    @user_info.save
    redirect_to user_path
  end
  
  def idhash_check
    # Страница проверки идентификатора пользователя (JS)
  end

  def info
    @user = OpenStruct.new
    if @user_info.present?
      @user.emails = @user_info["B3"]
      @user.skype = @user_info["B4"]
      @user.icq = @user_info["B5"]
      @user.jabber = @user_info["B6"]
      @user.phones = @user_info["B7"]
    end
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
    @user_trust_str_num = @user_info["B2"] if @user_info

    # Страница голосов в сети доверия (idhash, main_doc_url_key, verify_level, trust_level)
    @user_trust_votes = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_net)
    @user_trust_votes = @user_doc.add_worksheet(Settings.google.user.main_doc_pages.trust_net, 1000, 4) if !@user_trust_votes

    # Страница голосов в голосованиях (vote_doc_url_key, user_vote_doc_url_key)
    @user_votes = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.votes)
    @user_votes = @user_doc.add_worksheet(Settings.google.user.main_doc_pages.votes, 10000, 2) if !@user_votes

    # Регистрируем документ пользователя в документе сети доверия если его там еще нет
    row_num = 1
    user_found = false
    if @user_idhash.present? && @user_trust_str_num.blank?
      @trust_net_members.rows.each do |row|
        if row[0] == @user_idhash
          user_found = true
          if row[1] == @user_doc.key
            @user_trust_str_num = row_num
            break
          else
            flash[:alert] = I18n.t("errors.idhash_wrong_doc_key")
            redirect_to root_path
            break
          end
        end
        if row[0].blank?
          break
        end
        row_num += 1
      end

      if !user_found
        @trust_net_members["A#{row_num}"] = @user_idhash
        @trust_net_members["B#{row_num}"] = @user_doc.key
        @trust_net_members.save
        @user_trust_str_num = row_num
      end
      @user_info["B2"] = @user_trust_str_num
      @user_info.save
    end
  end

  def set_user_by_id
    @user_idhash = params[:idhash]

    # Ищем юзера в составе участников сети доверия
    @trust_net_members.rows.each do |row|
      if row[0] == @user_idhash
        @user_doc_key = row[1]
        break
      end
    end

    if @user_doc_key.present?
      @user_doc = user_session.spreadsheet_by_key(@user_doc_key)
      @user_info = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info)
      @user_idhash = @user_info["B1"] if @user_info
    end
  end
end
