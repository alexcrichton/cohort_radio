source :rubygems

gem 'rails', '3.1.0'

gem 'bson_ext'
gem 'mongoid'
gem 'mongoid_slug', :require => 'mongoid/slug'

# Authentication
gem 'cancan'
gem 'devise'

# Upload/audio processing gems
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'

# Display helpers
gem 'kaminari'
gem 'redcarpet'

# Asset Management
group :assets do
  gem 'jquery-rails'
  gem 'coffee-rails', '~> 3.1.0'
  gem 'sass-rails', '~> 3.1.0'
  gem 'ejs'
  gem 'uglifier'
end

group :development, :test do
  gem 'heroku'
  gem 'rspec-rails'
end

group :test do
  gem 'spork', '> 0.9.0.rc'
  gem 'database_cleaner'
end

group :heroku do
  gem 'therubyracer-heroku'
end

group :worker, :default do
  # WebSocket notifications
  gem 'pusher'

  # Queued processing
  gem 'resque'
  gem 'resque-status', :require => 'resque/status'
end

group :worker, :test do
  gem 'ruby-mp3info', :require => 'mp3info'
  gem 'flacinfo-rb', :require => 'flacinfo'
  gem 'mp4info', :git => 'git://github.com/danielwestendorf/ruby-mp4info.git',
    :ref => '7e8131719e'

  gem 'em-http-request' # Required for asynchronous pusher
  gem 'libwebsocket'
  gem 'fargo', :git => 'git://github.com/alexcrichton/fargo'
  gem 'ruby-shout', :require => 'shout'
  gem 'libxml-ruby', :require => 'libxml' # parsing output of last.fm
end

group :useful do
  gem 'guard-livereload'
  gem 'capistrano'
end
