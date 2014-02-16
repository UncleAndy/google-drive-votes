class SyncDataService
  SYNC_TASKS = {
    'NEW_MEMBER'    => SyncTasks::NewMember,
    'SERVERS'       => SyncTasks::Servers,
    'VERIFY_VOTE'   => SyncTasks::VerifyVote,
    'TRUST_VOTE'    => SyncTasks::TrustVote,
    'PROPERTY_VOTE' => SyncTasks::PropertyVote
  }
  
  def self.process_input
    SyncQueue.for_input.each do |sync|
      task = SYNC_TASKS[sync.cmd]
      if task.present?
        result = task.receive(sync.data)
        sync.update_attributes(:status => result)
      else
        sync.update_attributes(:status => 'no task')
      end
    end
  end

  def self.process_output
    SyncQueue.for_output.each do |sync|
      data = nil
      begin
        data = JSON.parse(sync.data)
      rescue JSON::ParserError
        data = nil
        Rails.logger.info("[SYNC OUT] Error parse sync JSON for #{sync.id}")
      end
      if data.present?
        data_str = {:query_id => sync.query_id, :cmd => query.cmd, :data => data}.to_json
        SyncHost.all.each do |host|
          uri = URI(host.url)

          request = Net::HTTP::Post.new(uri.path, initheader = {
            'Content-Type' =>'application/json',
            'X-Checksum' => gen_checksum(host.secret, data_str),
            'X-Host-Id' => Settings.host_id })
          request.body = data_str
          response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(request) }
          Rails.logger.info("[SYNC OUT] Sync with #{host.url} answer is #{response.code}/#{response.body}")
        end

        sync.update_attributes(:status => 'done')
      else
        sync.update_attributes(:status => 'error')
      end
    end
  end

  def self.gen_checksum(secret, data_str)
    check_string = "#{secret}:#{data_str}"
    Digest::SHA256.hexdigest(check_string)
  end
end
