# -*- encoding : utf-8 -*-
require 'yaml'

=begin
Общий способ работы с документами google.

Главный документ обновляется только после окончания рассчета результатов в БД.
При расчете в существенных для него данных пользователя ставится время текущего расчета.

Данные в БД синхронизируются с данными пользователя в его документе во время логина.

Документ пользователя обновляется параллельно с данными в БД с использованием oauth2 авторизации.
За счет обновления поля updated_at в БД всегда можно отследить какие данные обновились после последнего расчета.
=end

class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :gon_init
  
  def spaced_str(idhash)
    res = ''
    sep = ''
    if idhash.size > 16
      (idhash.size / 16).times do |idx|
        start = idx*16
        fin = start+16-1
        res = "#{res}#{sep}#{idhash[start..fin]}"
        sep = ' '
      end

      ost = idhash.size - (16 * (idhash.size / 16))
      if ost > 0
        start = (idhash.size / 16) * 16
        fin = idhash.size
        res = "#{res}#{sep}#{idhash[start..fin]}"
      end
    else
      res = idhash
    end
    res
  end
  helper_method :spaced_str

  def show_idhash(idhash)
    member = TrustNetMember.find_by_idhash(idhash)
    if member.present? && member.nick.present?
      "#{member.nick} / #{idhash[0..16]}..."
    else
      spaced_str(idhash)
    end
  end
  helper_method :show_idhash
  
  def google_action
    counter = 3
    success = false
    while counter > 0 do
      counter -= 1
      begin
        yield
        success = true
        break
      rescue GoogleDrive::AuthenticationError => e
        Rails.logger.info("GoogleDrive::AuthenticationError: try refresh token")
        refresh_token
      rescue OAuth2::Error => e
        Rails.logger.info("OAuth2::Error: try refresh token")
        refresh_token
      end
    end
    if !success
      session[:site_return_url] = request.env['REQUEST_URI']
      session[:last_query_method] = request.method
      redirect_to auth_path
      false
    else
      true
    end
  end

  def refresh_token
    Rails.logger.info("[refresh_token] Run")
    refresh_client_obj = OAuth2::Client.new(Settings.oauth2.client_id, Settings.oauth2.client_secret,
      :site => "https://accounts.google.com",
      :token_url => "/o/oauth2/token",
      :authorize_url => "/o/oauth2/auth")
    Rails.logger.info("[refresh_token] Request for refresh access token.")
    refresh_access_token_obj = OAuth2::AccessToken.new(refresh_client_obj,
                                                       session[:auth_token],
                                                       {refresh_token: session[:refresh_token]})
    refresh_access_token_obj.refresh!
    Rails.logger.info("[refresh_token] New access token = #{refresh_access_token_obj.token}")
    Rails.logger.info("[refresh_token] Access token ttl = #{refresh_access_token_obj.expires_in.to_i}")
    session[:auth_token] = refresh_access_token_obj.token
    if refresh_access_token_obj.expires_in.present?
      session[:auth_token_ttl] = DateTime.now.to_i + refresh_access_token_obj.expires_in.to_i
    else
      session[:auth_token_ttl] = ''
    end
    refresh_token_str = refresh_access_token_obj.refresh_token
    session[:refresh_token] = refresh_token_str if refresh_token_str.present?
    Rails.logger.info("[refresh_token] Finished")
  end
  
  private

  def login_required
    if !session[:auth_token].present? || !session[:refresh_token].present?
      session[:site_return_url] = request.env['REQUEST_URI']
      session[:last_query_method] = request.method
      redirect_to auth_path
    end
  end

  def check_preauth
    return google_action do
      Rails.logger.info("[check_preauth] Run for #{session.inspect}")
      doc_session = GoogleUserDoc.new(session)
      user_info = doc_session.doc_info_page
    end
  end
  
  def gon_init
    gon.is_ok = true
  end
end
