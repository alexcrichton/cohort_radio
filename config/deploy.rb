server "eve.alexcrichton.com", :app, :web, :db, :primary => true
ssh_options[:port] = 7779

set :user, "capistrano"
set :use_sudo, false

set :rake, "/opt/ruby1.8/bin/rake"

set :scm, :git
set :repository, "git://eve.alexcrichton.com/public/cohort_radio.git"
set :branch, "master"
set :deploy_via, :remote_cache

set :deploy_to, "/srv/http/cohort_radio"

before "deploy:setup", :db
after "deploy:update_code", "db:symlink"
# before "deploy:symlink", "push:restart"
# before "deploy:symlink", "worker:restart"

def script command
  run "cd #{current_path}; RAILS_ENV=production script/#{command}"
end

namespace :db do
  task :default do
    run "mkdir -p #{shared_path}/config"
    run "mkdir -p #{shared_path}/files"
  end

  desc "Make symlink for database yaml" 
  task :symlink do
    run "ln -nsf #{shared_path}/config/mail_auth.rb #{release_path}/config/initializers/"
    run "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/"
    run "ln -nsf #{shared_path}/files #{latest_release}/private"
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
