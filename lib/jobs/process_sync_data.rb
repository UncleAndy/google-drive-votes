# -*- encoding : utf-8 -*-
class Jobs::ProcessSyncData
  @queue = :process_sync_data

  def self.perform
    Rails.logger.info("[RESCUE SCHEDULER JOB] ProcessSyncData run")
    SyncDataService.process_input
    SyncDataService.process_output
  end
end
