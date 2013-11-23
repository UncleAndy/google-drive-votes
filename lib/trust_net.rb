class TrustNet
  def self.calculate
    Rails.logger.info("[TrustNet.calculate] Run")
    temp_result = {}
    Settings.trust_net_options.iteration_count.times do
      temp_result = calc_iteration(temp_result)
    end

    Rails.logger.info("[TrustNet.calculate] Save results")
    save_result(temp_result)
  end

  private

  def self.calc_iteration(temp_result = {})
    Rails.logger.info("[TrustNet.calculate] Run iteration")
    next_result = {}
    TrustNetMember.all.each do |member|
      member_id = '#{member.idhash}:#{member.doc_key}'
      Rails.logger.info("[TrustNet.calculate] Member: #{member_id}")
      UserTrustNetVote.by_owner(member.idhash).each do |vote|
        if vote.vote_idhash != member.idhash
          vote_id = '#{vote.vote_idhash}:#{vote.vote_doc_key}'
          
          verify_level = limit_levels(vote.vote_verify_level)
          trust_level = limit_levels(vote.vote_trust_level)
          Rails.logger.info("[TrustNet.calculate] Member: #{member_id} Vote: #{vote_id} #{verify_level} #{trust_level}")

          correction = 1.0
          if temp_result[member_id].present? && temp_result[member_id][:trust_level].present?
            correction = (temp_result[member_id][:trust_level] + 10.0) / 20.0;
          end
          Rails.logger.info("[TrustNet.calculate] Member: #{member_id} Vote: #{vote_id} correction #{correction}")

          verify_level *= correction
          trust_level *= correction

          Rails.logger.info("[TrustNet.calculate] Member: #{member_id} Vote: #{vote_id} levels after corrections #{verify_level} #{trust_level}")
          if next_result[vote_id].present?
            next_result[vote_id][:verify_level] =
                (next_result[vote_id][:verify_level].to_f * next_result[vote_id][:count] + verify_level.to_f)/(next_result[vote_id][:count] + 1)
            
            next_result[vote_id][:trust_level] =
                (next_result[vote_id][:trust_level].to_f * next_result[vote_id][:count] + trust_level.to_f)/(next_result[vote_id][:count] + 1)

            next_result[vote_id][:count] += 1
            Rails.logger.info("[TrustNet.calculate] changed result = #{next_result[vote_id]}")
          else
            next_result[vote_id] = {:idhash => vote.vote_idhash,
                                    :doc_key => vote.vote_doc_key,
                                    :verify_level => verify_level.to_f,
                                    :trust_level => trust_level.to_f,
                                    :count => 1}
            Rails.logger.info("[TrustNet.calculate] new result = #{next_result[vote_id]}")
          end
        end
      end
    end

    # Для всех, у кого количество голосов ниже определенного значения, учитываем всех до этого значения, как указавших уровень 0-0
    next_result.keys.each do |id|
      Rails.logger.info("[TrustNet.calculate] average loop for #{id}")
      if next_result[id][:count] < Settings.trust_net_options.average_limit
        Rails.logger.info("[TrustNet.calculate] for #{id} by max average")
        next_result[id][:verify_level] = next_result[id][:verify_level] * next_result[id][:count] / Settings.trust_net_options.average_limit.to_f
        next_result[id][:trust_level] = next_result[id][:trust_level] * next_result[id][:count] / Settings.trust_net_options.average_limit.to_f
      end
    end

    next_result
  end

  def self.limit_levels(level)
    if level > 10
      10
    elsif level < -10
      -10
    else
      level
    end
  end

  def self.save_result(result)
    result_time = DateTime.now

    result.keys.each do |id|
      row = result[id]
      TrustNetResult.create({:result_time => result_time,
                             :idhash => row[:idhash],
                             :doc_key => row[:doc_key],
                             :verify_level => row[:verify_level],
                             :trust_level => row[:trust_level],
                             :votes_count => row[:count]})
    end

    TrustNetResultHistory.create({:result_time => result_time})
  end
end
