source :rubygems

gem 'rails', '3.0.0.rc'
gem 'cancan', '>= 1.3'
gem 'authlogic', :git => 'git://github.com/odorcicd/authlogic.git', :branch => 'rails3'
gem 'paperclip', :git => 'git://github.com/dwalters/paperclip.git', :branch => 'rails3'
gem 'ruby-mp3info', :require => 'mp3info'
gem 'delayed_job'

gem 'will_paginate', :git => 'git://github.com/huerlisi/will_paginate.git', :branch => 'rails3'
gem 'scrobbler'
gem 'daemons'
gem 'shout', '2.1.1'
gem 'bluecloth'

gem 'haml'
gem 'paste', :git => 'git://github.com/alexcrichton/paste.git'

# If we need better searching, this should do the trick
# gem 'thinking-sphinx', :require => 'thinking_sphinx', :git => 'git://github.com/freelancing-god/thinking-sphinx.git', :branch => 'rails3'

group :development do
  gem 'rvm', '>=0.1.43'
  gem 'capistrano'
end

group :development, :test do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'bullet', '>=2.0.0.beta.3'
  gem 'ruby-growl'
end

group :production, :staging do
  gem 'mysql2'
  gem 'exception_notifier'
end

group :test do
  gem 'rspec-rails', '>=2.0.0.beta.19'
  gem 'factory_girl_rails'

  gem 'spork'
end
