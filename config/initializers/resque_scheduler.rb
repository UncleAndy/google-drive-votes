# -*- encoding : utf-8 -*-
require 'yaml'
require 'resque'

require 'resque_scheduler'
require 'resque_scheduler/server'

Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_scheduler.yml")

Resque::Server.use(Rack::Auth::Basic) do |user, password|
  user== 'admin' && password == 'resque'
end
