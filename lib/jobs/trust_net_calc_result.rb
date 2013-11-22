# -*- encoding : utf-8 -*-
class Jobs::TrustNetCalcResult
  @queue = :trust_net_calc_result

  def self.perform
    TrustNet.calculate
  end
end
