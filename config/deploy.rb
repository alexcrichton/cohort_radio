require 'rvm/capistrano'
require 'bundler/capistrano'

server 'eve.alexcrichton.com', :app, :web, :db, :primary => true
ssh_options[:port] = 7779

set :user, 'capistrano'
set :use_sudo, false
set :rails_env do (ENV['RAILS_ENV'] || 'production').to_sym end
set :rvm_ruby_string, 'ree'
set :bundle_flags, '--deployment'

set :scm, :git
set :repository, 'git://github.com/alexcrichton/cohort_radio.git'
set :branch, 'master'
set :deploy_via, :remote_cache

set :deploy_to, '/srv/http/cohort_radio'

before 'deploy:setup', :db
after 'deploy:update_code', 'db:symlink'
# before "deploy:symlink", "push:restart"
# before "deploy:symlink", "worker:restart"

def script command, opts = {}
  run "cd #{latest_release}; RAILS_ENV=#{rails_env} script/#{command}"
end

namespace :db do
  task :default do
    run "mkdir -p #{shared_path}/config"
    run "mkdir -p #{shared_path}/files"
    run "mkdir -p #{shared_path}/fargo"
    run "mkdir -p #{shared_path}/bundle"
  end

  desc "Make symlink for database yaml"
  task :symlink do
    run "ln -nsf #{shared_path}/config/mail_auth.rb #{release_path}/config/initializers/"
    run "ln -nsf #{shared_path}/config/session_store.rb #{release_path}/config/initializers/"
    run "ln -nsf #{shared_path}/config/cookie_verification_secret.rb #{release_path}/config/initializers/"
    run "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/"
    run "ln -nsf #{shared_path}/config/fargo.yml #{release_path}/config/"
    run "ln -nsf #{shared_path}/config/radio.yml #{release_path}/config/"
    run "ln -nsf #{shared_path}/config/exceptional.yml #{release_path}/config/"
    run "ln -nsf #{shared_path}/files #{latest_release}/private"
    run "ln -nsf #{shared_path}/fargo #{latest_release}/tmp/fargo"
    run "ln -nsf #{shared_path}/bundle #{latest_release}/.bundle"
  end

end

# run through phusion passenger on nginx
namespace :deploy do
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
  task :start, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
  task :stop, :roles => :app do
    # Do nothing, don't want to kill nginx
  end
end

namespace :radio do
  task :restart, :roles => :app do
    sudo 'god restart cradio-radio'
  end
  task :start, :roles => :app do
    sudo 'god start cradio-radio'
  end
  task :stop, :roles => :app do
    sudo 'god stop cradio-radio'
  end
end

namespace :worker do
  task :restart, :roles => :app do
    sudo 'god restart cradio-delayed_job'
  end
  task :start, :roles => :app do
    sudo 'god restart cradio-delayed_job'
  end
  task :stop, :roles => :app do
    sudo 'god restart cradio-delayed_job'
  end
end

namespace :fargo do
  task :restart, :roles => :app do
    sudo 'god restart cradio-fargo'
  end
  task :start, :roles => :app do
    sudo 'god start cradio-fargo'
  end
  task :stop, :roles => :app do
    sudo 'god stop cradio-fargo'
  end
end
