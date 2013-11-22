class TrustNetResult < ActiveRecord::Base
  attr_accessible :result_time, :idhash, :doc_key, :verify_level, :trust_level, :votes_count

  default_scope ->{ where(:result_time => TrustNetResultHistory.maximum(:result_time)) }
end
