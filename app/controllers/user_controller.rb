# -*- encoding : utf-8 -*-
class UserController < ApplicationController
  before_filter :login_required
  before_filter :set_user_by_id, :only => [:info]

  rescue_from GoogleDrive::AuthenticationError, :with => :user_google_session_reopen
  
  def show
    redirect_to new_user_path and return if session[:idhash].blank?

    @idhash = session[:idhash]
    @doc_key = session[:doc_key]
    @user = UserOption.find_or_create_by_idhash(session[:idhash])
  end

  def new
  end

  def create
    idhash = params[:user][:idhash]
    if idhash.present? && session[:auth_token].present?
      session[:idhash] = idhash

      GoogleUserDoc.init(session)
      user_info = GoogleUserDoc.doc_info_page
      user_info["B1"] = idhash
      user_info.save

      # Регистрация в сети доверия (только в БД)
      if user_info["B1"] == idhash
        rec = TrustNetMember.register(idhash, GoogleUserDoc.user_doc.key)
        if rec.errors.present?
          flash[:alert] = rec.errors.full_messages.join(', ')
          redirect_to :back and return
        end
      end
    end
    redirect_to user_path
  end

  def update
    user = UserOption.find_or_create_by_idhash(session[:idhash])
    user.update_attributes(params[:user])
    
    GoogleUserDoc.init(session)
    user_info = GoogleUserDoc.doc_info_page
    user_info["B3"] = params[:user][:emails]
    user_info["B4"] = params[:user][:skype]
    user_info["B5"] = params[:user][:icq]
    user_info["B6"] = params[:user][:jabber]
    user_info["B7"] = params[:user][:phones]
    user_info["B8"] = params[:user][:facebook]
    user_info["B9"] = params[:user][:vk]
    user_info["B10"] = params[:user][:odnoklassniki]
    user_info.save
    redirect_to user_path
  end
  
  def idhash_check
    # Страница проверки идентификатора пользователя (JS)
  end

  def info
    @idhash = params[:idhash]
    @user_member = TrustNetMember.find_by_idhash(@idhash) if @idhash
    @doc_key = @user_member.doc_key if @user_member
    @user = UserOption.find_or_create_by_idhash(@idhash) if @idhash
  end
  
  private


  def set_user_by_id
    @user_idhash = params[:idhash]

    # Ищем юзера в составе участников сети доверия

    if @user_doc_key.present?
      GoogleUserDoc.init(session)
      @user_doc = GoogleUserDoc.user_google_session.spreadsheet_by_key(@user_doc_key)
      @user_info = @user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info)
      @user_idhash = @user_info["B1"] if @user_info
    end
  end
  
  def user_google_session_reopen
    session[:auth_token] = nil
    login_required
  end
end
