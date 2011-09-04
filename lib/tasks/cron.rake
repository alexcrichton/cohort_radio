task :cron do
  begin
    require File.expand_path('../../../config/initializers/resque', __FILE__)
    require 'resque'
    require File.expand_path('../../../app/workers/clean_artists', __FILE__)
    Resque.enqueue CleanArtists
  rescue => e
    Exceptional.catch e if defined?(Exceptional)
    raise e
  end
end
