#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'resque_scheduler/tasks'

require File.expand_path('../config/application', __FILE__)

GoogleDriveVotes::Application.load_tasks

task "resque:setup" => :environment do
  ENV['QUEUE'] ||= '*'
  Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
end

namespace :resque do
  desc "let resque workers always load the rails environment"
  task :setup => :environment do
  end

  desc "kill all workers (using -QUIT), god will take care of them"
  task :stop_workers => :environment do
    pids = Array.new

    Resque.workers.each do |worker|
      pids << worker.to_s.split(/:/).second
    end

    if pids.size > 0
      system("kill -QUIT #{pids.join(' ')}")
    end

    # god should handle the restart
  end
end
