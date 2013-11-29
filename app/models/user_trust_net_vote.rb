class UserTrustNetVote < ActiveRecord::Base
  attr_accessible :idhash, :doc_key, :vote_idhash, :vote_doc_key, :vote_verify_level, :vote_trust_level

  scope :by_owner, lambda { |idhash, doc_key| where(:idhash => idhash, :doc_key => doc_key) }
  scope :to_user, lambda { |idhash| where(:vote_idhash => idhash) }
  scope :to_user_and_doc, lambda { |idhash, doc_key| where(:vote_idhash => idhash, :vote_doc_key => doc_key) }

  def complex_id
    UserTrustNetVote.complex_id(vote_idhash, vote_doc_key)
  end

  def self.complex_id(idhash, doc_key)
    "#{idhash}:#{doc_key}"
  end

  def self.parse_complex_id(complexid)
    complexid.split(':')
  end

  def owner
    TrustNetMember.find_by_idhash_and_doc_key(idhash, doc_key)
  end
end
