class TrustNetMember < ActiveRecord::Base
  attr_accessible :idhash, :doc_key, :doc_key_type, :nick

  scope :by_data, lambda{ |idhash, doc_key, doc_key_type| where(:idhash => idhash, :doc_key => doc_key, :doc_key_type => doc_key_type) }
  
  def options
    UserOption.find_or_create_by_idhash_and_doc_key(idhash, doc_key)
  end
  
  def self.register(idhash, doc_key, doc_key_type, nick)
    idhash_exists = find_by_idhash(idhash)
    doc_key_exists = find_by_doc_key_and_doc_key_type(doc_key, doc_key_type)

    if (idhash_exists && !doc_key_exists) || (!idhash_exists && doc_key_exists)
      model = self.new
      model.errors[:base] << I18n.t('errors.idhash_wrong_doc_key') if idhash_exists
      model.errors[:base] << I18n.t('errors.doc_key_wrong_idhash') if doc_key_exists
      model
    elsif model = find_by_idhash_and_doc_key_and_doc_key_type(idhash, doc_key, doc_key_type)
      model.update_attributes(:nick => nick)
      model
    else
      create({:idhash => idhash, :doc_key => doc_key, :doc_key_type => doc_key_type, :nick => nick})
      SyncQueue.create(:status => 'out', :cmd => 'NEW_MEMBER', :data => { :idhash => idhash, :doc_key => doc_key, :doc_key_type => doc_key_type, :nick => nick })
    end
  end
end
