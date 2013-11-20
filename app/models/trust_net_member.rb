class TrustNetMember < ActiveRecord::Base
  attr_accessible :idhash, :doc_key

  def self.register(idhash, doc_key)
    idhash_exists = find_by_idhash(idhash)
    doc_key_exists = find_by_doc_key(doc_key)

    if (idhash_exists && !doc_key_exists) || (!idhash_exists && doc_key_exists)
      model = self.new
      model.errors[:base] << I18n.t('errors.idhash_wrong_doc_key') if idhash_exists
      model.errors[:base] << I18n.t('doc_key_wrong_idhash') if doc_key_exists
      model
    else
      create({:idhash => idhash, :doc_key => doc_key})
    end
  end
end