# -*- encoding : utf-8 -*-
require 'resque'

Resque.redis = "#{Settings.redis_for_resque.host}:#{Settings.redis_for_resque.port}:#{Settings.redis_for_resque.db}"

Dir["#{Rails.root}/lib/jobs/*.rb"].each { |file| require file }
