source :rubygems

gem 'rails', '3.0.0'

# Authentication
gem 'cancan', '>= 1.3'
gem 'authlogic', :git => 'git://github.com/odorcicd/authlogic.git', :branch => 'rails3'

# Upload/audio processing gems
gem 'carrierwave', '>= 0.5.0.beta'
gem 'ruby-mp3info', :require => 'mp3info'
gem 'flacinfo-rb', :require => 'flacinfo'
gem 'mp4info', :git => 'git://github.com/danielwestendorf/ruby-mp4info',
  :ref => '7e8131719e'

gem 'delayed_job' # Background conversion jobs
gem 'scrobbler'   # Album art for songs

# Daemons and we stream to icecast using ruby-shout
gem 'daemons'
gem 'fargo', :git => 'git://github.com/alexcrichton/fargo.git' # DC Client
gem 'ruby-shout', '>= 2.2.0.pre2', :require => 'shout'

# Display helpers
gem 'will_paginate', :git => 'git://github.com/huerlisi/will_paginate.git', :branch => 'rails3'
gem 'bluecloth'

# Asset Management
gem 'compass'
gem 'paste', :git => 'git://github.com/alexcrichton/paste.git'

group :development do
  gem 'rvm', '>=0.1.43'
  gem 'capistrano'
end

group :development, :test do
  gem 'sqlite3-ruby', :require => 'sqlite3'
end

group :production, :staging do
  gem 'mysql2'
end

group :test do
  gem 'rspec-rails', '>=2.0.0.beta.19'
  gem 'factory_girl_rails'

  gem 'spork'
end
