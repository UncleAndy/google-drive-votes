class GoogleUserDoc
  @@user_google_session = nil
  @@user_doc = nil
  @@user_doc_info = nil
  @@user_doc_trust_votes = nil
  @@user_doc_votes = nil
  @@session = nil

  def self.init(session)
    @@session = session
  end
  
  def self.user_google_session(token)
    return @@user_google_session if @@user_google_session.present?
    @@user_google_session = GoogleDrive.login_with_oauth(token) if token.present?
  end
  
  def self.user_doc
    return @@user_doc if @@user_doc.present?
    google_session = user_google_session(@@session[:auth_token])
    collection = google_session.collection_by_title(Settings.google.user.collection)
    @@user_doc = collection.spreadsheets(:title => Settings.google.user.main_doc)[0] if google_session
  end

  def self.doc_info_page
    return @@user_doc_info if @@user_doc_info.present?
    doc = user_doc
    @@user_doc_info = doc.worksheet_by_title(Settings.google.user.main_doc_pages.user_info) if doc
  end

  def self.doc_trust_votes_page
    return @@user_doc_trust_votes if @user_doc_trust_votes.present?
    doc = user_doc
    @@user_doc_trust_votes = doc.worksheet_by_title(Settings.google.user.main_doc_pages.trust_net) if doc
  end

  def self.doc_votes_page
    return @@user_doc_votes if @@user_doc_votes.present?
    doc = user_doc
    @@user_doc_votes = doc.worksheet_by_title(Settings.google.user.main_doc_pages.votes) if doc
  end
end