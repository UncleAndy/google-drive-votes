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
    auth_token = @client.auth_code.get_token(params[:code], :redirect_uri => Settings.oauth2.redirect_url)
    session[:auth_token] = auth_token.token
    session[:refresh_token] = auth_token.refresh_token
    Rails.logger.info("AUTH: Auth token #{session[:auth_token]}")
    Rails.logger.info("AUTH: Refresh token #{session[:refresh_token]}")
    
    # Открываем документ пользователя и запоминаем в сессии его idhash
    user_doc, user_info, user_trust_votes, user_votes = set_idhash(auth_token.token)
    sync_data(session[:idhash], user_doc, user_info, user_trust_votes, user_votes)

    redirect_to session[:site_return_url] || root_path
  end

  private

  def create_oauth2_client
    @client = OAuth2::Client.new(Settings.oauth2.client_id, Settings.oauth2.client_secret,
      :site => "https://accounts.google.com",
      :token_url => "/o/oauth2/token",
      :authorize_url => "/o/oauth2/auth")
  end

  def set_idhash(token)
    google_session = nil
    user_doc = nil
    user_info = nil
    user_trust_votes = nil
    user_votes = nil
    if token.present?
      google_action do
        google_session = GoogleUserDoc.user_google_session(token)
        Rails.logger.info("DBG: user doc title '#{Settings.google.user.main_doc}'")
        collection = google_session.collection_by_title(Settings.google.user.collection)
        user_doc = collection.spreadsheets(:title => Settings.google.user.main_doc)[0] if collection
      end
      if user_doc
        google_action do
          user_info = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info)

          # Проверяем что документ доступен для записи
          test_val = rand().to_s
          user_info["A2"] = test_val
          user_info.save
          idx = 1

          # В цикле пытаемся найти другие документы с таким именем доступные для записи в данной коллекции
          while user_info["A2"] != test_val
            user_doc = collection.spreadsheets(:title => Settings.google.user.main_doc)[idx] if collection
            user_info = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info)
            idx += 1
            
            user_info["A2"] = test_val
            user_info.save
          end
          
          if user_info["A2"] != test_val
            session[:idhash] = ''
            session[:doc_key] = ''
            user_doc = nil
            user_info = nil
            flash[:alert] = I18n.t("errors.not_your_document")
          else
            user_info["A2"] = ''
            user_info.save
            
            idhash = user_info["B1"] if user_info
            doc_key = user_doc.key

            # Проверяем соответствие idhash и документа
            if !TrustNetMember.find_by_idhash(idhash) || TrustNetMember.find_by_idhash_and_doc_key(idhash, doc_key)
              session[:idhash] = idhash
              session[:doc_key] = doc_key
            else
              session[:idhash] = ''
              session[:doc_key] = doc_key
              user_doc = nil
              user_info = nil
              flash[:alert] = I18n.t("errors.not_your_idhash")
            end
          end
        end
      else
        user_doc, user_info, user_trust_votes, user_votes = create_user_doc(google_session)
        session[:doc_key] = user_doc.key if user_doc
      end
    end
    [user_doc, user_info, user_trust_votes, user_votes]
  end

  def create_user_doc(google_session)
    user_doc = nil
    user_info = nil
    user_trust_votes = nil
    user_votes = nil
    
    google_action do
      collection = google_session.collection_by_title(Settings.google.user.collection)
      collection = google_session.root_collection.create_subcollection(Settings.google.user.collection) if !collection

      user_doc = google_session.create_spreadsheet(Settings.google.user.main_doc)
      if user_doc
        collection.add(user_doc) if collection

        user_doc.acl.push({:scope_type => "default", :role => "reader"})

        # Страница info
        user_info = user_doc.worksheets()[0]
        user_info.title = Settings.google.user.main_doc_pages.user_info
        user_info.max_rows = 1000
        user_info.max_cols = 3
        user_info["A1"] = I18n.t("user_info.idhash")
        user_info["A3"] = I18n.t("simple_form.labels.defaults.emails")
        user_info["A4"] = I18n.t("simple_form.labels.defaults.skype")
        user_info["A5"] = I18n.t("simple_form.labels.defaults.icq")
        user_info["A6"] = I18n.t("simple_form.labels.defaults.jabber")
        user_info["A7"] = I18n.t("simple_form.labels.defaults.phones")
        user_info["A8"] = I18n.t("simple_form.labels.defaults.facebook")
        user_info["A9"] = I18n.t("simple_form.labels.defaults.vk")
        user_info["A10"] = I18n.t("simple_form.labels.defaults.odnoklassniki")
        user_info.save

        # Страница голосов в сети доверия (idhash, main_doc_url_key, verify_level, trust_level)
        user_trust_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.trust_net, 1000, 4)

        # Страница голосов в голосованиях (vote_doc_url_key, user_vote_doc_url_key)
        user_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.votes, 50000, 2)
      end
    end
    [user_doc, user_info, user_trust_votes, user_votes]
  end

  # Синхронизация данных в БД с документом
  def sync_data(idhash, user_doc, user_info, user_trust_votes, user_votes)
    return if user_doc.blank? || idhash.blank?
    google_action do
      user_info = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info) if !user_info
      user_trust_votes = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_net) if !user_trust_votes

      # Настройки пользователя
      user = UserOption.find_or_create_by_idhash_and_doc_key(idhash, user_doc.key)
      user.update_attributes({
                              :emails => user_info["B3"],
                              :skype => user_info["B4"],
                              :icq => user_info["B5"],
                              :jabber => user_info["B6"],
                              :phones => user_info["B7"],
                              :facebook => user_info["B8"],
                              :vk => user_info["B9"],
                              :odnoklassniki => user_info["B10"]
                              })

      # Голоса в сети доверия
      # добавляем БД присутствующие в документе, но отсутствующие в БД
      # обновляем существующие голоса в соответствии со значением в документе
      doc_trust_votes = {}
      dup_rows = []
      user_trust_votes.rows.each_with_index do |row, idx|
        id = "#{row[0]}:#{row[1]}"

        # Проверяем не продублирован-ли голос
        if doc_trust_votes[id]
          # Есть дубль - второй голос помечаем на удаление (запоминаем номер строки) и игнориуем
          row_num = idx + 1
          dup_rows.push row_num
          next
        end
        
        doc_trust_votes[id] = true
        
        break if row[0].blank? || row[1].blank? || row[2].blank? || row[3].blank?
        vote = UserTrustNetVote.find_by_idhash_and_vote_idhash_and_vote_doc_key(idhash, row[0], row[1])
        if vote
          vote.update_attributes({:vote_verify_level => row[2], :vote_trust_level => row[3]}) if vote.vote_verify_level != row[2].to_i || vote.vote_trust_level != row[3].to_i
        else
          UserTrustNetVote.create({:idhash => idhash, :doc_key => user_doc.key, :vote_idhash => row[0], :vote_doc_key => row[1], :vote_verify_level => row[2], :vote_trust_level => row[3]})
        end
      end

      # Цикл по номерам дублированных строк и их удаление в документе сдвигом вверх
      dup_rows.each_with_index do |dup_row, idx|
        row_num = dup_row - idx
        while user_trust_votes["A#{row_num}"].present?
          user_trust_votes["A#{row_num}"] = user_trust_votes["A#{row_num+1}"]
          user_trust_votes["B#{row_num}"] = user_trust_votes["B#{row_num+1}"]
          user_trust_votes["C#{row_num}"] = user_trust_votes["C#{row_num+1}"]
          user_trust_votes["D#{row_num}"] = user_trust_votes["D#{row_num+1}"]
          row_num += 1
        end
      end
      user_trust_votes.save
      
      # удаляем из БД отсутствующие в документе, но присутствующие в БД
      UserTrustNetVote.by_owner(idhash, user_doc.key).each do |vote|
        id = "#{vote.vote_idhash}:#{vote.vote_doc_key}"
        if !doc_trust_votes[id]
          vote.destroy
        end
      end

      # Проверяем регистрацию пользователя в сети доверия
      member = TrustNetMember.find_by_idhash(idhash)
      if !member
        doc_member = TrustNetMember.find_by_doc_key(user_doc.key)
        TrustNetMember.create({:idhash => idhash, :doc_key => user_doc.key}) if !doc_member
      end
    end
  end
end
