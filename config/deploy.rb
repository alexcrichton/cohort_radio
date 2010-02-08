server "eve.alexcrichton.com", :app, :web, :db, :primary => true
set :rake, "/opt/ruby1.8/bin/rake"
ssh_options[:port] = 7779

set :user, "capistrano"
set :use_sudo, false

set :scm, :git
set :repository, "git://github.com/alexcrichton/cohort_radio.git"
set :branch, ENV['BRANCH'] || "master"
set :rails_env, ENV['RAILS_ENV'] || "production"
set :deploy_via, :remote_cache

set :deploy_to, "/srv/http/cohort_radio"

before "deploy:setup", :db
after "deploy:update_code", "db:symlink"
# before "deploy:symlink", "push:restart"
# before "deploy:symlink", "worker:restart"

namespace :db do
  task :default do
    run "mkdir -p #{shared_path}/config"
  end

  desc "Make symlink for database yaml" 
  task :symlink do
    run "ln -nsf #{shared_path}/config/mail_auth.rb #{release_path}/config/initializers/"
    run "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/"
  end
end

# run through phusion passenger on nginx
namespace :deploy do 
  task :restart, :roles => :app do
    run "touch #{release_path}/tmp/restart.txt"
  end
  task :start, :roles => :app do
    run "touch #{release_path}/tmp/restart.txt"
  end
  task :stop, :roles => :app do
    # Do nothing, don't want to kill nginx
  end
end

namespace :worker do 
  task :restart, :roles => :app do
    run "RAILS_ENV=#{rails_env} #{release_path}/script/delayed_job restart"
  end
  task :start, :roles => :app do
    run "RAILS_ENV=#{rails_env} #{release_path}/script/delayed_job start"
  end
  task :stop, :roles => :app do
    run "RAILS_ENV=#{rails_env} #{release_path}/script/delayed_job stop"
  end
end
