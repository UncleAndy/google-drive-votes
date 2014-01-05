class SynchronizeController < ApplicationController
  def create
    json_text = request.raw_post
    host_id = request.headers["X-Host-Id"]
    host = SyncHost.find_by_id(host_id)
    if host.present? && host.active? && request.headers["X-Checksum"] == SyncDataService.gen_checksum(host.secret, json_text)
      begin
        json = JSON.parse(json_text)
        if !SyncQueue.find_by_query_id(json['query_id'])
          SyncQueue.create(:status => 'new', :query_id => json['query_id'], :cmd => json['cmd'], :data => json['data'].to_json)
        end
      rescue JSON::ParserError
        render text: "Error: json parse error" and return
      end
      render text: "OK"
    else
      render text: "Error: checksum authorization error"
    end
  end
end
