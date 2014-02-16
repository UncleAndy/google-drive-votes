module SyncTasks
  class Servers < SyncTasks::Base
    def self.receive(json)
      data = JSON.parse(json)
      if data.present? && data['servers'].present?
        data['servers'].each do |server|
          srv = Server.find_by_url(server)
          Server.create(:url => server) if srv.blank?
        end
      end
      return('out')
    end
  end
end

