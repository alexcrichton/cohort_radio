require 'resque/tasks'

namespace :resque do
  task :preload => :environment
end
