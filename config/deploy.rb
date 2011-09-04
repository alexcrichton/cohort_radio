require 'bundler/capistrano'

set :application, 'cohort-radio'
set :scm, :git
set :repository, 'git@github.com:alexcrichton/cohort_radio.git'
set :branch, 'master'
set :deploy_via, :remote_cache
set :ssh_options, { :forward_agent => true, :port => 7779 }

set :use_sudo, false
set :deploy_to, "/srv/http/#{application}"
set :user,  'alex'

set :bundle_without, [:development, :test, :heroku]

server 'eve.alexcrichton.com', :app, :web, :db, :primary => true

namespace :deploy do
  task :setup_config do
    run "mkdir -p #{shared_path}/config"
    run "touch #{shared_path}/config/env"
  end
  after 'deploy:setup', 'deploy:setup_config'

  task :link_env do
    run "ln -nsf #{shared_path}/config/env #{latest_release}/.env"
  end
  after 'deploy:update_code', 'deploy:link_env'
end
