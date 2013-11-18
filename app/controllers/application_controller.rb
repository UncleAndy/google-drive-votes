require 'yaml'

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :google_session_prepare
  before_filter :main_document_prepare
  before_filter :gon_init
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

  def idhash_str(idhash)
    res = ''
    sep = ''
    (idhash.size / 16).times do |idx|
      start = idx*16
      fin = start+16-1
      res = "#{res}#{sep}#{idhash[start..fin]}"
      sep = '-'
    end
    res
  end
  helper_method :idhash_str
  
  private

  def gon_init
    gon.is_ok = true
  end
  
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
    if @main_google_session
      new_doc = false
      @trust_net = @main_google_session.spreadsheet_by_title(Settings.google.main.trust_net) if !@trust_net
      if !@trust_net
        new_doc = true
        @trust_net = @main_google_session.create_spreadsheet(Settings.google.main.trust_net)
      end

      # Создаем страницы в документе сети доверия
      # Страница участников
      @trust_net_members = @trust_net.worksheet_by_title(Settings.google.main.pages.members)
      if !@trust_net_members
        if new_doc
          @trust_net_members = @trust_net.worksheets()[0]
          @trust_net_members.title = Settings.google.main.pages.members
          @trust_net_members.max_rows = 100000
          @trust_net_members.max_cols = 2
          @trust_net_members.save
        else
          @trust_net_members = @trust_net.add_worksheet(Settings.google.main.pages.members, 10000, 2)
        end
      end

      # Страница настроек
      @trust_net_options = @trust_net.worksheet_by_title(Settings.google.main.pages.options)
      @trust_net_options = @trust_net.add_worksheet(Settings.google.main.pages.options, 100, 2) if !@trust_net_options
      @itaration_count = @trust_net_options["B1"]
      if @itaration_count.blank?
        @itaration_count = Settings.trust_net_default.itaration_count
        @trust_net_options["A1"] = I18n.t('trust_net.itaration_count')
        @trust_net_options["B1"] = @itaration_count
        @trust_net_options.save
      end
      @average_limit = @trust_net_options["B2"]
      if @average_limit.blank?
        @average_limit = Settings.trust_net_default.average_limit
        @trust_net_options["A2"] = I18n.t('trust_net.average_limit')
        @trust_net_options["B2"] = @average_limit
        @trust_net_options.save
      end
      
      # Страница результатов
      @trust_net_results = @trust_net.worksheet_by_title(Settings.google.main.pages.results)
      @trust_net_results = @trust_net.add_worksheet(Settings.google.main.pages.results, 10000, 5) if !@trust_net_results
    end
  end
  
  def login_required
    if !@user_google_session
      session[:site_return_url] = request.env['REQUEST_URI']
      redirect_to auth_path
    end
  end

  def user_google_session_reopen
    @user_google_session = nil
    login_required
  end
end
