class UserTrustVote < ActiveRecord::Base
  attr_accessible :idhash, :doc_key, :vote_idhash, :vote_trust_level

  scope :by_owner, lambda { |idhash, doc_key| where(:idhash => idhash, :doc_key => doc_key) }
  scope :to_user, lambda { |idhash| where(:vote_idhash => idhash) }

  def owner
    TrustNetMember.find_by_idhash_and_doc_key(idhash, doc_key)
  end
end
