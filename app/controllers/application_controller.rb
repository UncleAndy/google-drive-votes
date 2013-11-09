require 'yaml'

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :google_session_prepare
  rescue_from GoogleDrive::AuthenticationError, :with => :user_google_session_reopen

  
  def user_session
    @user_google_session
  end
  helper_method :user_session

  def main_session
    @main_google_session
  end
  helper_method :main_session

  def trust_net_doc
    main_document_prepare if !@trust_net
    @trust_net
  end
  helper_method :trust_net_doc
  
  private

  def google_session_prepare
    @user_google_session = GoogleDrive.login_with_oauth(session[:auth_token]) if session[:auth_token].present? && !@user_google_session

    @main_google_session = GoogleDrive.restore_session(session[:main_auth_tokens]) if session[:main_auth_tokens].present? && !@main_google_session
    if !@main_google_session
      google_auth = YAML.load_file("#{Rails.root}/config/google.yml")
      @main_google_session = GoogleDrive.login(google_auth['login'], google_auth['password']) if google_auth
      session[:main_auth_tokens] = @main_google_session.auth_tokens
    end
  end

  def main_document_prepare
    if !@trust_net && @main_google_session
      @trust_net = @main_google_session.spreadsheet_by_title(Settings.google.main.trust_net)
      if !@trust_net
        @trust_net = @main_google_session.create_spreadsheet(Settings.google.main.trust_net)
      end
    end
  end
  
  def login_required
    redirect_to auth_path if !@user_google_session
  end

  def user_google_session_reopen
    @user_google_session = nil
    login_required
  end
end
