source :rubygems

gem 'rails', '3.1.0.rc6'

gem 'bson_ext'
gem 'mongoid'

# Authentication
gem 'cancan'
gem 'devise'

# Upload/audio processing gems
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'

# Display helpers
gem 'kaminari'
gem 'redcarpet'

# WebSocket notifications
gem 'pusher'

# Asset Management
gem 'coffee-script'
gem 'jquery-rails'
gem 'sass-rails', '~> 3.1.0.rc'

# Queued processing
gem 'resque'
gem 'resque-status', :require => 'resque/status'

group :development, :test do
  gem 'heroku'
  gem 'rspec-rails'
end

group :test do
  gem 'spork', '> 0.9.0.rc'
  gem 'database_cleaner'
end

group :production do
  gem 'therubyracer-heroku'
  gem 'uglifier'
end

group :worker, :test do
  gem 'ruby-mp3info', :require => 'mp3info'
  gem 'flacinfo-rb', :require => 'flacinfo'
  gem 'mp4info', :git => 'git://github.com/danielwestendorf/ruby-mp4info.git',
    :ref => '7e8131719e'

  gem 'scrobbler'   # Album art for songs

  gem 'fargo', :git => 'git://github.com/alexcrichton/fargo' # DC Client
  gem 'ruby-shout', :require => 'shout'
end
