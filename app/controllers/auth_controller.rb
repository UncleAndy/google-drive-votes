class AuthController < ApplicationController
  skip_before_filter :google_session
  before_filter :create_oauth2_client
  
  def show
    @auth_url = @client.auth_code.authorize_url(
      :redirect_uri => Settings.oauth2.redirect_url,
      :scope => "https://spreadsheets.google.com/feeds/")
    redirect_to @auth_url
  end

  def login
    auth_token = @client.auth_code.get_token(params[:code], :redirect_uri => Settings.oauth2.redirect_url)
    Rails.logger.info("DBG: token = #{auth_token.token}")
    session[:auth_token] = auth_token.token
    redirect_to root_path
  end

  private

  def create_oauth2_client
    @client = OAuth2::Client.new(Settings.oauth2.client_id, Settings.oauth2.client_secret,
      :site => "https://accounts.google.com",
      :token_url => "/o/oauth2/token",
      :authorize_url => "/o/oauth2/auth")
  end
end
