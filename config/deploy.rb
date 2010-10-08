require 'rvm/capistrano'
require 'bundler/capistrano'

server 'eve.alexcrichton.com', :app, :web, :db, :primary => true
ssh_options[:port] = 7779

set :user, 'capistrano'
set :use_sudo, false
set :rails_env do (ENV['RAILS_ENV'] || 'production').to_sym end
set :rvm_ruby_string, 'ree'

set :scm, :git
set :repository, 'git://github.com/alexcrichton/cohort_radio.git'
set :branch, 'master'
set :deploy_via, :remote_cache

set :deploy_to, '/srv/http/cohort_radio'

before 'deploy:setup', :db
after 'deploy:update_code', 'db:symlink'

namespace :db do
  task :default do
    run "mkdir -p #{shared_path}/config"
    run "mkdir -p #{shared_path}/files"
    run "mkdir -p #{shared_path}/fargo"
  end

  desc "Make symlink for database yaml"
  task :symlink do
    run "ln -nsf #{shared_path}/files #{latest_release}/private && " +
      "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/ && " +
      "ln -nsf #{shared_path}/config/mail_auth.rb #{release_path}/config/initializers && " +
      "ln -nsf #{shared_path}/config/radio.rb #{release_path}/config/initializers && " +
      "ln -nsf #{shared_path}/fargo #{latest_release}/tmp/fargo"
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

namespace :pusher do
  task :restart, :roles => :app do
    sudo 'god restart cradio-pusher'
  end
  task :start, :roles => :app do
    sudo 'god restart cradio-pusher'
  end
  task :stop, :roles => :app do
    sudo 'god restart cradio-pusher'
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
