task :cron do
  require 'resque'
  require File.expand_path('../../../app/workers/clean_artists', __FILE__)
  Resque.enqueue CleanArtists
end
