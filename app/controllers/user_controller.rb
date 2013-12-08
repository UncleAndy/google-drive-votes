# -*- encoding : utf-8 -*-
class UserController < ApplicationController
  before_filter :check_preauth, :only => [:new]
  before_filter :login_required
  
  def show
    redirect_to new_user_path and return if session[:idhash].blank?

    @idhash = session[:idhash]
    @doc_key = session[:doc_key]
    @member = TrustNetMember.find_by_idhash_and_doc_key(@idhash, @doc_key)
    @nick = @member.nick if @member
    @user = UserOption.find_or_create_by_idhash_and_doc_key(@idhash, @doc_key)
  end

  def new
  end

  def create
    idhash = params[:user][:idhash]
    if idhash.present? && session[:auth_token].present?
      session[:idhash] = idhash
      nick = params[:user][:nick]

      return false if !google_action do
        doc_session = GoogleUserDoc.new(session)
        user_info = doc_session.doc_info_page
        user_info["B1"] = idhash
        user_info["C1"] = nick
        user_info.save

        # Регистрация в сети доверия (только в БД)
        if user_info["B1"] == idhash
          rec = TrustNetMember.register(idhash, doc_session.user_doc.key, nick)
          if rec.errors.present?
            flash[:alert] = rec.errors.full_messages.join(', ')
            redirect_to :back and return
          end
        end
      end
    end
    redirect_to user_path
  end

  def update
    user = UserOption.find_or_create_by_idhash_and_doc_key(session[:idhash], session[:doc_key])
    user.update_attributes(params[:user])
    
    return false if !google_action do
      doc_session = GoogleUserDoc.new(session)
      user_info = doc_session.doc_info_page
      user_info["B3"] = params[:user][:emails]
      user_info["B4"] = params[:user][:skype]
      user_info["B5"] = params[:user][:icq]
      user_info["B6"] = params[:user][:jabber]
      user_info["B7"] = params[:user][:phones]
      user_info["B8"] = params[:user][:facebook]
      user_info["B9"] = params[:user][:vk]
      user_info["B10"] = params[:user][:odnoklassniki]
      user_info.save
    end
    redirect_to user_path
  end
  
  def idhash_check
    # Страница проверки идентификатора пользователя (JavaScript)
  end

  def doc_info
    @doc_key = params[:doc_key]
    if @doc_key.blank? && params[:idhash].present?
      @user_member = TrustNetMember.order('created_at desc').where(:idhash => params[:idhash]).first
    else
      @user_member = TrustNetMember.find_by_doc_key(@doc_key) if @doc_key
    end
    if @user_member
      @idhash = @user_member.idhash
      @doc_key = @user_member.doc_key
      @nick = @user_member.nick
      @user = UserOption.find_or_create_by_idhash_and_doc_key(@idhash, @doc_key) if @idhash && @doc_key
    else
      flash[:alert] = I18n.t("errors.member_not_found")
      @idhash = params[:idhash]
      @nick = ''
      @user = OpenStruct.new
    end
  end

  def idhash_info
    @idhash = params[:idhash]
    @members = TrustNetMember.where(:idhash => @idhash)
  end
end
