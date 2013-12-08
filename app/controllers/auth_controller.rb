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
      user_doc, doc_session = set_idhash(auth_token.token)
      sync_data(session[:idhash], user_doc, doc_session)

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
    google_session = nil
    passport = nil
    user_info = nil
    doc_session = nil
    if token.present?
      Rails.logger.info("[Auth#se4t_idhash] token present")
      doc_session = GoogleUserDoc.new(session)
      google_action do
        google_session = doc_session.user_google_session(token)
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

  # Синхронизация данных в БД с паспортом
  def sync_data(idhash, user_doc, doc_session)
    return if user_doc.blank? || idhash.blank?
    google_action do
      doc_session = GoogleUserDoc.new(session) if !doc_session
      user_doc = doc_session.passport if !user_doc
      user_info = doc_session.doc_info_page
      user_verify_votes = doc_session.doc_verify_votes_page
      user_trust_votes = doc_session.doc_trust_votes_page
      user_property_votes = doc_session.doc_property_votes_page

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


      #################################################################
      # Голоса верификации
      # добавляем БД присутствующие в документе, но отсутствующие в БД
      # обновляем существующие голоса в соответствии со значением в документе
      doc_verify_votes = {}
      dup_rows = []
      user_verify_votes.rows.each_with_index do |row, idx|
        id = "#{row[0]}:#{row[1]}"

        # Проверяем не продублирован-ли голос
        if doc_verify_votes[id]
          # Есть дубль - второй голос помечаем на удаление (запоминаем номер строки) и игнориуем
          row_num = idx + 1
          dup_rows.push row_num
          next
        end
        
        doc_verify_votes[id] = true
        
        break if row[0].blank? || row[1].blank? || row[2].blank?
        vote = UserVerifyVote.find_by_idhash_and_vote_idhash_and_vote_doc_key(idhash, row[0], row[1])
        if vote
          vote.update_attributes({:vote_verify_level => row[2]}) if vote.vote_verify_level != row[2].to_i
        else
          UserVerifyVote.create({:idhash => idhash, :doc_key => user_doc.key, :vote_idhash => row[0], :vote_doc_key => row[1], :vote_verify_level => row[2]})
        end
      end

      # Цикл по номерам дублированных строк и их удаление в документе сдвигом вверх
      dup_rows.each_with_index do |dup_row, idx|
        row_num = dup_row - idx
        while user_verify_votes["A#{row_num}"].present?
          user_verify_votes["A#{row_num}"] = user_verify_votes["A#{row_num+1}"]
          user_verify_votes["B#{row_num}"] = user_verify_votes["B#{row_num+1}"]
          user_verify_votes["C#{row_num}"] = user_verify_votes["C#{row_num+1}"]
          user_verify_votes["D#{row_num}"] = user_verify_votes["D#{row_num+1}"]
          row_num += 1
        end
      end
      user_verify_votes.save
      
      # удаляем из БД отсутствующие в документе, но присутствующие в БД
      UserVerifyVote.by_owner(idhash, user_doc.key).each do |vote|
        id = "#{vote.vote_idhash}:#{vote.vote_doc_key}"
        if !doc_verify_votes[id]
          vote.destroy
        end
      end

      #################################################################
      # Голоса доверия
      doc_trust_votes = {}
      dup_rows = []
      user_trust_votes.rows.each_with_index do |row, idx|
        id = row[0]

        # Проверяем не продублирован-ли голос
        if doc_trust_votes[id]
          # Есть дубль - второй голос помечаем на удаление (запоминаем номер строки) и игнориуем
          row_num = idx + 1
          dup_rows.push row_num
          next
        end

        doc_trust_votes[id] = true

        break if row[0].blank? || row[1].blank?
        vote = UserTrustVote.find_by_idhash_and_doc_key_and_vote_idhash(idhash, user_doc.key, row[0])
        if vote
          vote.update_attributes({:vote_trust_level => row[1]}) if vote.vote_trust_level != row[1].to_i
        else
          UserTrustVote.create({:idhash => idhash, :doc_key => user_doc.key, :vote_idhash => row[0], :vote_trust_level => row[1]})
        end
      end

      # Цикл по номерам дублированных строк и их удаление в документе сдвигом вверх
      dup_rows.each_with_index do |dup_row, idx|
        row_num = dup_row - idx
        while user_trust_votes["A#{row_num}"].present?
          user_trust_votes["A#{row_num}"] = user_trust_votes["A#{row_num+1}"]
          user_trust_votes["B#{row_num}"] = user_trust_votes["B#{row_num+1}"]
          row_num += 1
        end
      end
      user_trust_votes.save

      # удаляем из БД отсутствующие в документе, но присутствующие в БД
      UserTrustVote.by_owner(idhash, user_doc.key).each do |vote|
        id = vote.vote_idhash
        if !doc_trust_votes[id]
          vote.destroy
        end
      end

      #################################################################
      # Голоса свойств
      doc_property_votes = {}
      dup_rows = []
      user_property_votes.rows.each_with_index do |row, idx|
        id = "#{row[0]}:#{row[1]}"

        # Проверяем не продублирован-ли голос
        if doc_property_votes[id]
          # Есть дубль - второй голос помечаем на удаление (запоминаем номер строки) и игнориуем
          row_num = idx + 1
          dup_rows.push row_num
          next
        end

        doc_property_votes[id] = true

        break if row[0].blank? || row[2].blank?
        vote = UserPropertyVote.find_by_idhash_and_doc_key_and_vote_idhash_and_vote_property_key(idhash, user_doc.key, row[0], row[1])
        if vote
          vote.update_attributes({:vote_property_level => row[2]}) if vote.vote_property_level != row[2].to_i
        else
          UserPropertyVote.create({:idhash => idhash, :doc_key => user_doc.key, :vote_idhash => row[0], :vote_property_key => row[1], :vote_property_level => row[2]})
        end
      end

      # Цикл по номерам дублированных строк и их удаление в документе сдвигом вверх
      dup_rows.each_with_index do |dup_row, idx|
        row_num = dup_row - idx
        while user_property_votes["A#{row_num}"].present?
          user_property_votes["A#{row_num}"] = user_property_votes["A#{row_num+1}"]
          user_property_votes["B#{row_num}"] = user_property_votes["B#{row_num+1}"]
          user_property_votes["C#{row_num}"] = user_property_votes["C#{row_num+1}"]
          user_property_votes["D#{row_num}"] = user_property_votes["D#{row_num+1}"]
          row_num += 1
        end
      end
      user_property_votes.save

      # удаляем из БД отсутствующие в документе, но присутствующие в БД
      UserPropertyVote.by_owner(idhash, user_doc.key).each do |vote|
        id = "#{vote.vote_idhash}:#{vote.vote_property_key}"
        if !doc_property_votes[id]
          vote.destroy
        end
      end

      
      # Проверяем регистрацию пользователя в сети доверия
      nick = user_info["C1"]
      member = TrustNetMember.find_by_idhash_and_doc_key(idhash, user_doc.key)
      if !member
        doc_member = TrustNetMember.find_by_doc_key(user_doc.key)
        TrustNetMember.create({:idhash => idhash, :doc_key => user_doc.key, :nick => nick}) if !doc_member
      elsif member.nick != nick
        member.update_attributes(:nick => nick)
      end
    end
  end
end
