# -*- encoding : utf-8 -*-
class Jobs::SyncSelfServer
  @queue = :sync_self_server

  def self.perform
    Rails.logger.info("[RESCUE SCHEDULER JOB] SyncSelfServer run")
    SyncQueue.create(:status => 'out', :cmd => 'SERVERS', :data => { :servers => [Settings.server_url] })
  end
end
