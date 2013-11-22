# -*- encoding : utf-8 -*-
class Jobs::TrustNetCalcResult
  @queue = :trust_net_calc_result

  def self.perform
    Rails.logger.info("[RESCUE SCHEDULER JOB] TrustNetCalcResult run")
    TrustNet.calculate
  end
end
