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

# Should contain RADIO_URL, REDISTOGO_URL, PUSHER_URL,
# FARGO_DESTINATION, and MONGOHQ_URL
envfile = File.expand_path('../../.env', __FILE__)
if File.exists?(envfile)
  env = {'RAILS_ENV' => 'production'}
  File.readlines(envfile).each { |line|
    key, value = line.split('=', 2)
    env[key] = value.chomp
  }
  set :default_environment, env
end

namespace :deploy do
  task :create_upload_dirs do
    run "mkdir -p #{shared_path}/tmp-downloads #{shared_path}/private"
  end
  after 'deploy:setup', 'deploy:create_upload_dirs'

  desc 'Link the shared private directory for files into place'
  task :link_private_dir do
    run "ln -nsf #{shared_path}/private #{latest_release}/private"
  end
  after 'deploy:update_code', 'deploy:link_private_dir'

  desc 'Push the latest code to heroku'
  task :push_to_heroku do
    system 'git push heroku master'
  end
  before 'deploy:update_code', 'deploy:push_to_heroku'
end

namespace :workers do
  task :start_queue do
    run "cd #{current_release} && " \
        "nohup bundle exec rake resque:work" \
        "QUEUE=cleaner,convert_song,scrobble,songs --trace " \
        "&>> log/queue.log &|"
  end

  task :start_fargo do
    run "cd #{current_release} && " \
        "nohup bundle exec script/worker &>> log/fargo.log &|"
  end

  task :start do
    foreman.start_queue
    foreman.start_fargo
  end

  desc 'Stop just the queue worker process'
  task :stop_queue do
    run "pkill -QUIT -f 'resque.*scrobble'; true"
  end

  desc 'Stop just the fargo worker process'
  task :stop_fargo do
    run "pkill -QUIT -f 'script/worker'; true"
  end

  desc 'Stop the foreman processes'
  task :stop do
    foreman.stop_queue
    foreman.stop_fargo
  end

  desc 'Restart the foreman processes'
  task :restart do
    foreman.stop
    foreman.start
  end
end
