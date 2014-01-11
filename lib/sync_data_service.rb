class SyncDataService
  def self.process_input
    SyncQueue.for_input.each do |sync|
      if sync.cmd == 'NEW_MEMBER'
        result = 'out'
        begin
          sync_new_member(JSON.parse(sync.data))
        rescue JSON::ParserError
          result = 'error'
        ensure
          sync.update_attributes(:status => result)
        end
      elsif sync.cmd == 'SERVERS'
        result = 'out'
        begin
          sync_new_servers(JSON.parse(sync.data))
        rescue JSON::ParserError
          result = 'error'
        ensure
          sync.update_attributes(:status => result)
        end
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
  
  private

  def sync_new_member(data)
    member = TrustNetMember.find_by_idhash_and_doc_key(data['idhash'], data['doc_key'])
    if member
      member.update_attributes(:nick => data['nick'])
    else
      TrustNetMember.create(:idhash => data['idhash'], :doc_key => data['doc_key'], :nick => data['nick'])
    end
  end

  def sync_new_servers(data)
    if data.servers.present?
      data.servers.each do |server|
        srv = Server.find_by_url(server)
        Server.create(:url => server) if srv.blank?
      end
    end
  end
end
