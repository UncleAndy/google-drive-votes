# -*- encoding : utf-8 -*-
namespace :trustnet do
  desc "Расчитываем общий результат уровней доверия и верификации по сети доверия"
  task :calc_result => :environment do
    TrustNet.calculate
  end
end
