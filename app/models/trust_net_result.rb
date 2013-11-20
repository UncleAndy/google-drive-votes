class TrustNetResult < ActiveRecord::Base
  attr_accessible :idhash, :doc_key, :verify_level, :trust_level, :votes_count
end
