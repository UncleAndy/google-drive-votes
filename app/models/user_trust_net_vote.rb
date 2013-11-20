class UserTrustNetVote < ActiveRecord::Base
  attr_accessible :idhash, :vote_idhash, :vote_doc_key, :vote_verify_level, :vote_trust_level

  scope :by_owner, lambda { |idhash| where(:idhash => idhash) }
end
