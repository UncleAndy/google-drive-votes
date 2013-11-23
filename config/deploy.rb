require 'bundler/capistrano'
load 'deploy/assets'

set :repository, 'git@github.com:UncleAndy/google-drive-votes.git'
set :scm, :git

server '193.106.94.91', :app, :web, :db, :primary => true

set :ssh_options, { :forward_agent => true }
default_run_options[:shell] = 'bash -l'

set :user, 'deployer'
set :use_sudo, false
set :rails_env, 'production'

set :project_name, 'google_trust_net'

set :deploy_to, "/home/deployer/projects/#{ project_name }"

def run_remote_rake(rake_cmd)
  rake_args = ENV['RAKE_ARGS'].to_s.split(',')
  cmd = "cd #{fetch(:latest_release)} && #{fetch(:rake, "rake")} RAILS_ENV=#{fetch(:rails_env, "production")} #{rake_cmd}"
  cmd += "['#{rake_args.join("','")}']" unless rake_args.empty?
  run cmd
  set :rakefile, nil if exists?(:rakefile)
end

desc "Restart of Unicorn"
task :restart, :except => { :no_release => true } do
  run "kill -s QUIT `cat /home/deployer/projects/#{ project_name }/shared/pids/unicorn.pid`"
  run "sleep 3"
  run "cd #{current_path} ; bundle exec unicorn_rails -D -E production -c config/unicorn.rb"
  run_remote_rake "resque:restart_workers"
  run_remote_rake "resque:restart_scheduler"
end

desc "Start unicorn"
task :start, :except => { :no_release => true } do
  run "cd #{current_path} ; bundle exec unicorn_rails -D -E production -c config/unicorn.rb"
end

desc "Stop unicorn"
task :stop, :except => { :no_release => true } do
  run "kill -s QUIT `cat /home/deployer/projects/#{ project_name }/shared/pids/unicorn.pid`"
end

after 'deploy:finalize_update', 'deploy:symlink_db'

namespace :deploy do
  desc "Symlinks the database.yml"
  task :symlink_db, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}/shared/config/google.yml #{release_path}/config/google.yml"
  end

  desc "Restart Resque Workers"
  task :restart_workers, :roles => :db do
    run_remote_rake "resque:restart_workers"
  end

  desc "Restart Resque scheduler"
  task :restart_scheduler, :roles => :db do
    run_remote_rake "resque:restart_scheduler"
  end
end
