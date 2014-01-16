class GoogleUserDoc
  
  def initialize(options)
    super()
    if options && options[:auth_token]
      @session = options
    else
      @login = options[:login]
      @password = options[:password]
    end
  end
  
  def user_google_session
    return @user_google_session if @user_google_session.present?
    if @session.present? && @session[:auth_token].present?
      @user_google_session = GoogleDrive.login_with_oauth(@session[:auth_token])
    else
      @user_google_session = GoogleDrive.login(@login, @password)
    end
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

  def doc_property_votes_page
    return @user_doc_property_votes if @user_doc_property_votes.present?
    doc = user_doc
    @user_doc_property_votes = doc.worksheet_by_title(Settings.google.user.main_doc_pages.property_votes) if doc
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

  def passport_by_key(passport_key)
    
  end
  
  def passport_sync(passport_doc)
    return if passport_doc.blank?
    info_page = passport_doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info)
    idhash = info_page["B1"] if info_page
    return if idhash.blank?
    
    # Проверяем регистрацию пользователя в сети доверия
    nick = info_page["C1"]
    member = TrustNetMember.find_by_idhash_and_doc_key(idhash, passport_doc.key)
    if !member
      doc_member = TrustNetMember.find_by_doc_key(passport_doc.key)
      if !doc_member
        TrustNetMember.create({:idhash => idhash, :doc_key => passport_doc.key, :nick => nick})
      elsif doc_member.idhash != idhash
        # Меняем idhash
        doc_member.update_attributes(:idhash => idhash)
        member = doc_member
      end
    end
    if member && member.nick != nick
      member.update_attributes(:nick => nick)
    end

    # Синхронизировать настройки пользователя
    user = UserOption.find_or_create_by_idhash_and_doc_key(idhash, passport_doc.key)
    user.update_attributes({
                            :emails   => info_page["B3"],
                            :skype    => info_page["B4"],
                            :icq      => info_page["B5"],
                            :jabber   => info_page["B6"],
                            :phones   => info_page["B7"],
                            :facebook => info_page["B8"],
                            :vk       => info_page["B9"],
                            :odnoklassniki => info_page["B10"]
                            })

    passport_sync_verify_votes(idhash, passport_doc)
    passport_sync_trust_votes(idhash, passport_doc)
    passport_sync_property_votes(idhash, passport_doc)
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
    google_session = user_google_session
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

    # Страница голосов доверия
    user_trust_votes = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_votes)
    user_trust_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.trust_votes, 1000, 2) if !user_trust_votes

    # Страница заверяемых свойств (idhash, id_property, level)
    user_property_votes = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.property_votes)
    user_property_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.property_votes, 1000, 3) if !user_property_votes

    # Страница регистрируемых действий пользователя (time, type, id, data)
    user_votes = user_doc.worksheet_by_title(Settings.google.user.main_doc_pages.actions)
    user_votes = user_doc.add_worksheet(Settings.google.user.main_doc_pages.actions, 50000, 4) if !user_votes
  end

  def user_doc
    return @user_doc if @user_doc.present?
    google_session = user_google_session
    collection = google_session.collection_by_title(Settings.google.user.collection) if google_session

    if collection.present?
      idx = 0
      # Проверяем все документы в коллекции пока не найдем тот, который может исправлять текущий пользователь
      # или пока не переберем все документы
      test_page = nil
      begin
        @user_doc = collection.spreadsheets(:title => Settings.google.user.main_doc)[idx]
        break if !@user_doc

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
      if test_page.present?
        test_page["A#{row_num}"] = ''
        test_page.save
      end
    end

    @user_doc
  end

  # Синхронизация голосов верификации
  def passport_sync_verify_votes(idhash, passport_doc)
    return if !passport_doc
    user_verify_votes = passport_doc.worksheet_by_title(Settings.google.user.main_doc_pages.verify_votes)
    return if !user_verify_votes
    
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
  end

  # Синхронизация голосов доверия
  def passport_sync_trust_votes(idhash, passport_doc)
    return if !passport_doc
    user_trust_votes = passport_doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_votes)
    return if !user_trust_votes

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
  end
  
  # Синхронизация голосов свойств
  def passport_sync_property_votes(idhash, passport_doc)
    return if !passport_doc
    user_property_votes = passport_doc.worksheet_by_title(Settings.google.user.main_doc_pages.property_votes)
    return if !user_property_votes
    
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
  end
end
