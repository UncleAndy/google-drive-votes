require 'yaml'

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :google_session

  def user_session
    @user_google_session
  end
  helper_method :user_session

  def main_session
    @main_google_session
  end
  helper_method :main_session
  
  private

  def google_session
    if !@user_google_session
      @user_google_session = GoogleDrive.restore_session(session[:auth_token]) if session[:auth_token].present?
      @user_google_session = GoogleDrive.login_with_oauth(session[:auth_token]) if session[:auth_token].present? && !@user_google_session
    end

    if !@main_google_session
      @main_google_session = GoogleDrive.restore_session(session[:main_auth_token]) if session[:main_auth_token].present?
      if !@main_google_session
        google_auth = YAML.load_file("#{Rails.root}/config/google.yml")
        @main_google_session = GoogleDrive.login(google_auth['login'], google_auth['password']) if google_auth
        session[:main_auth_token] = @main_google_session.auth_token
      end
    end
  end
end
