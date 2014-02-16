module SyncTasks
  class NewMember < SyncTasks::Base
    def self.receive(json)
      result = 'out'
      begin
        data = JSON.parse(json)
        member = TrustNetMember.by_data(data['idhash'], data['doc_key'], data['doc_key_type']).first
        if member
          member.update_attributes(:nick => data['nick'])
        else
          TrustNetMember.create(:idhash => data['idhash'], :doc_key => data['doc_key'], :doc_key_type => data['doc_key_type'], :nick => data['nick'])
        end
      rescue JSON::ParserError
        result = 'error'
      rescue Exception => e
        Rails.logger.info("Exception: #{e.inspect}")
        result = 'error'
      ensure
        return(result)
      end
    end
  end
end

