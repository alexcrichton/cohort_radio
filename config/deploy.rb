server "eve.alexcrichton.com", :app, :web, :db, :primary => true
ssh_options[:port] = 7779
# default_run_options[:pty] = true
default_run_options[:shell] = true

set :user, "capistrano"
set :use_sudo, false

set :scm, :git
set :repository, "git://github.com/alexcrichton/cohort_radio.git"
set :branch, "master"
set :deploy_via, :remote_cache

set :deploy_to, "/srv/http/cohort_radio"

before "deploy:setup", :db
after "deploy:update_code", "db:symlink"
# before "deploy:symlink", "push:restart"
# before "deploy:symlink", "worker:restart"

def script command, opts = {}
  run "cd #{current_path}; RAILS_ENV=#{opts[:env] || 'production'} script/#{command}"
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

namespace :bundler do
  task :install, :roles => :app do
    run "cd #{current_path} && bundle install #{shared_path}/bundle"
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
    script 'radio restart'
  end
  task :start, :roles => :app do
    script 'radio start'
  end
  task :stop, :roles => :app do
    script 'radio stop'
  end
end

namespace :worker do 
  task :restart, :roles => :app do
    script 'delayed_job restart'
  end
  task :start, :roles => :app do
    script 'delayed_job start'
  end
  task :stop, :roles => :app do
    script 'delayed_job stop'
  end
end

namespace :fargo do 
  task :restart, :roles => :app do
    script 'fargo restart'
  end
  task :start, :roles => :app do
    script 'fargo start'
  end
  task :stop, :roles => :app do
    script 'fargo stop'
  end
end
