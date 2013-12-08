class UserPropertyVote < ActiveRecord::Base
  attr_accessible :idhash, :doc_key, :vote_idhash, :vote_property_key, :vote_property_level

  scope :by_owner, lambda { |idhash, doc_key| where(:idhash => idhash, :doc_key => doc_key) }
  scope :to_user, lambda { |idhash| where(:vote_idhash => idhash) }
  scope :to_property, lambda { |property_key| where(:vote_property_key => property_key) }
end
