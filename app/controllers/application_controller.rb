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

  rescue_from GoogleDrive::AuthenticationError, :with => :user_google_session_reopen
  rescue_from OAuth2::Error, :with => :user_google_session_reopen
  
  before_filter :gon_init
  
  def spaced_str(idhash)
    res = ''
    sep = ''
    (idhash.size / 16).times do |idx|
      start = idx*16
      fin = start+16-1
      res = "#{res}#{sep}#{idhash[start..fin]}"
      sep = ' '
    end
    res
  end
  helper_method :spaced_str
  
  private

  def login_required
    if !session[:auth_token].present?
      session[:site_return_url] = request.env['REQUEST_URI']
      redirect_to auth_path
    end
  end

  def user_google_session_reopen
    session[:auth_token] = nil
    login_required
  end
  
  def gon_init
    gon.is_ok = true
  end
end
