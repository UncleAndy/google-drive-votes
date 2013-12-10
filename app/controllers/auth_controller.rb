# -*- encoding : utf-8 -*-
class AuthController < ApplicationController
  before_filter :create_oauth2_client
  
  def show
    @auth_url = @client.auth_code.authorize_url(
      :redirect_uri => Settings.oauth2.redirect_url,
      :access_type => "offline",
      :approval_prompt => 'force',
      :scope =>
        "https://docs.google.com/feeds/ " +
        "https://docs.googleusercontent.com/ " +
        "https://spreadsheets.google.com/feeds/")
    redirect_to @auth_url
  end

  def login
    begin
      auth_token = @client.auth_code.get_token(params[:code], :redirect_uri => Settings.oauth2.redirect_url)
      session[:auth_token] = auth_token.token
      if auth_token.expires_in.present?
        session[:auth_token_ttl] = DateTime.now.to_i + auth_token.expires_in.to_i
      else
        session[:auth_token_ttl] = ''
      end
      session[:refresh_token] = auth_token.refresh_token
      Rails.logger.info("AUTH: Auth token #{session[:auth_token]}")
      Rails.logger.info("AUTH: Refresh token #{session[:refresh_token]}")

      # Открываем документ пользователя и запоминаем в сессии его idhash
      google_action do
        user_doc, doc_session = set_idhash(auth_token.token)
        doc_session.passport_sync(doc_session.passport)
      end

      flash[:notice] = I18n.t('redo_required') if session[:last_query_method].present? && session[:last_query_method].upcase != 'GET'
      session[:last_query_method] = ''
      redirect_to session[:site_return_url] || root_path
    rescue OAuth2::Error
      redirect_to auth_path
    end
  end

  private

  def create_oauth2_client
    @client = OAuth2::Client.new(Settings.oauth2.client_id, Settings.oauth2.client_secret,
      :site => "https://accounts.google.com",
      :token_url => "/o/oauth2/token",
      :authorize_url => "/o/oauth2/auth")
  end

  def set_idhash(token)
    Rails.logger.info("[Auth#set_idhash] run")
    passport = nil
    user_info = nil
    doc_session = nil
    if token.present?
      Rails.logger.info("[Auth#se4t_idhash] token present")
      google_action do
        doc_session = GoogleUserDoc.new(session)
        passport = doc_session.passport
      end
      if passport
        google_action do
          user_info = passport.worksheet_by_title(Settings.google.user.main_doc_pages.user_info)
          Rails.logger.info("[Auth#set_idhash] user_info = #{user_info.inspect}")

          idhash = user_info["B1"] if user_info
          doc_key = passport.key
          Rails.logger.info("[Auth#set_idhash] idhash = #{idhash}, doc_key = #{doc_key}")

          # Проверяем соответствие idhash и документа
          # Пропускаем если idhash новый или если пара
          if idhash.present?
            if (TrustNetMember.find_by_idhash_and_doc_key(idhash, doc_key) ||
                (!TrustNetMember.find_by_idhash(idhash) && !TrustNetMember.find_by_doc_key(doc_key)))
              Rails.logger.info("[Auth#set_idhash] check member OK: session[idhash] = #{idhash}, session[doc_key] = #{doc_key}")
              session[:idhash] = idhash
              session[:doc_key] = doc_key
            else
              Rails.logger.info("[Auth#set_idhash] check member BAD: session[idhash] = , session[doc_key] = #{doc_key}")
              session[:idhash] = ''
              session[:doc_key] = doc_key
              user_info = nil
              flash[:alert] = I18n.t("errors.not_your_idhash")
            end
          else
            Rails.logger.info("[Auth#set_idhash] check member BAD (idhash empty): session[idhash] = , session[doc_key] = #{doc_key}")
            session[:idhash] = ''
            session[:doc_key] = doc_key
            user_info = nil
          end
        end
      else
        Rails.logger.info("[Auth#set_idhash] user doc not found: create")
        session[:idhash] = ''
        session[:doc_key] = ''
        flash[:alert] = I18n.t("errors.can_not_create_passport")
      end
    end
    [passport, doc_session]
  end
end
