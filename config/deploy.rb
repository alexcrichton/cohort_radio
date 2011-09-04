require 'bundler/capistrano'

set :application, 'cohort-radio'
set :scm, :git
set :repository, 'git@github.com:alexcrichton/cohort_radio.git'
set :branch, 'master'
set :deploy_via, :remote_cache
set :ssh_options, { :forward_agent => true, :port => 7779 }

set :use_sudo, false
set :deploy_to, "/srv/http/#{application}"
set :user, 'alex'
set :default_shell, '/bin/zsh'

set :bundle_without, [:development, :test, :heroku, :assets]

server 'eve.alexcrichton.com', :app, :web, :db, :primary => true

namespace :deploy do
  task :create_upload_dirs do
    run "mkdir -p #{shared_path}/tmp-downloads " +
        "#{shared_path}/config #{shared_path}/private"
  end
  after 'deploy:setup', 'deploy:create_upload_dirs'

  task :link_private_dir do
    run "ln -nsf #{shared_path}/private #{latest_release}/private"
  end
  after 'deploy:update_code', 'deploy:link_private_dir'
end

namespace :foreman do
  task :start do
    run "cd #{current_release} && " \
        "nohup bundle exec foreman start " \
          "--env #{shared_path}/config/env " \
          "--procfile #{current_release}/.foreman " \
          "--log #{shared_path}/log " \
          "--user #{user} &>> log/foreman.log &|"
  end

  task :stop do
    run "cd #{current_release} && kill $(pgrep -f foreman)"
  end

  task :restart do
    foreman.stop
    foreman.start
  end
end
