source :rubygems

gem 'rails', '3.0.0'

# Authentication
gem 'cancan'
gem 'devise'

# Upload/audio processing gems
gem 'carrierwave', '>= 0.5.0.beta'
gem 'ruby-mp3info', :require => 'mp3info'
gem 'flacinfo-rb', :require => 'flacinfo'
gem 'mp4info', :git => 'git://github.com/danielwestendorf/ruby-mp4info',
  :ref => '7e8131719e'

gem 'scrobbler'   # Album art for songs

# Daemons and we stream to icecast using ruby-shout
gem 'daemons'
gem 'fargo', :git => 'git://github.com/alexcrichton/fargo.git' # DC Client
gem 'ruby-shout', :require => 'shout'
gem 'em-websocket'

# Display helpers
gem 'will_paginate', :git => 'git://github.com/huerlisi/will_paginate.git', :branch => 'rails3'
gem 'bluecloth'

# Asset Management
gem 'compass'
gem 'paste', :git => 'git://github.com/alexcrichton/paste.git'

group :development do
  gem 'rvm'
  gem 'capistrano'
  gem 'sqlite3-ruby', :require => 'sqlite3'
end

group :production do
  gem 'mysql2'
end
