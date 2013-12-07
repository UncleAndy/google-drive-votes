class GoogleUserDoc
  
  def initialize(session)
    super()
    @session = session
  end
  
  def user_google_session(token)
    return @user_google_session if @user_google_session.present?
    @user_google_session = GoogleDrive.login_with_oauth(token) if token.present?
  end
  
  def user_doc
    return @user_doc if @user_doc.present?
    google_session = user_google_session(@session[:auth_token])
    collection = google_session.collection_by_title(Settings.google.user.collection) if google_session

    if collection.present?
      idx = 0
      # Проверяем все документы в коллекции пока не найдем тот, который может исправлять текущий пользователь
      # или пока не переберем все документы
      begin
        @user_doc = collection.spreadsheets(:title => Settings.google.user.main_doc)[idx]

        test_page = @user_doc.worksheets()[0]

        # Ищем первую пустую ячейку в столбце A
        row_num = 1
        while test_page["A#{row_num}"].present?
          row_num += 1
        end

        # Вносим в нее случайное тестовое значение
        test_val = rand().to_s
        test_page["A#{row_num}"] = test_val
        test_page.save
        test_page.reload

        idx += 1
      end while @user_doc && test_page["A#{row_num}"] != test_val
    end
    @user_doc
  end

  def doc_info_page
    return @user_doc_info if @user_doc_info.present?
    doc = user_doc
    @user_doc_info = doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info) if doc
  end

  def doc_verify_votes_page
    return @user_doc_verify_votes if @user_doc_verify_votes.present?
    doc = user_doc
    @user_doc_verify_votes = doc.worksheet_by_title(Settings.google.user.main_doc_pages.verify_votes) if doc
  end

  def doc_trust_votes_page
    return @user_doc_trust_votes if @user_doc_trust_votes.present?
    doc = user_doc
    @user_doc_trust_votes = doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_votes) if doc
  end

  def doc_votes_page
    return @user_doc_votes if @user_doc_votes.present?
    doc = user_doc
    @user_doc_votes = doc.worksheet_by_title(Settings.google.user.main_doc_pages.votes) if doc
  end

  def passport
    passport_doc = user_doc()
    passport_doc = passport_create if !passport_doc
    passport_check_pages(passport_doc)
    passport_doc
  end

  private
  
  def clear_all_singletons
    @user_google_session = nil
    @user_doc = nil
    @user_doc_info = nil
    @user_doc_trust_votes = nil
    @user_doc_votes = nil
  end

  def passport_create
    google_session = @user_google_session
    collection = google_session.collection_by_title(Settings.google.user.collection)
    collection = google_session.root_collection.create_subcollection(Settings.google.user.collection) if !collection

    user_doc = google_session.create_spreadsheet(Settings.google.user.main_doc)
    if user_doc
      collection.add(user_doc) if collection
      user_doc.acl.push({:scope_type => "default", :role => "reader"})
    end
    user_doc
  end

  def passport_check_pages(user_doc)
    # Страница info
    user_info = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info)
    if !user_info
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
    end

    # Страница голосов верификации в сети доверия (idhash, main_doc_url_key, verify_level)
    user_verify_votes = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.verify_votes)
    user_verify_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.verify_votes, 1000, 3) if !user_verify_votes

    # Страница голосов в голосованиях (vote_doc_url_key, user_vote_doc_url_key)
    user_votes = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.votes)
    user_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.votes, 30000, 3) if !user_votes

    # Страница голосов доверия
    user_trust_votes = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_votes)
    user_trust_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.trust_votes, 1000, 2) if !user_trust_votes

    # Страница заверяемых свойств (idhash, id_property, level)
    user_property_votes = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.property_votes)
    user_property_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.property_votes, 1000, 3) if !user_property_votes
  end
end
