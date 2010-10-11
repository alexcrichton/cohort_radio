require 'pathname'

rails_root = '/srv/http/cohort_radio/current'

%w{radio fargo pusher}.each do |daemon|
  God.watch do |w|

    w.name     = "cradio-#{daemon}"
    w.group    = 'cradio'
    w.interval = 30.seconds # default

    w.start = "script/#{daemon} -d"
    w.dir   = rails_root
    w.env   = { 'RAILS_ENV' => 'production' }
    w.log   = File.expand_path(rails_root + "/../shared/log/#{daemon}.log")

    w.uid   = 'capistrano'
    w.gid   = 'http'

    # retart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 300.megabytes
        c.times = 2
      end
    end

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end

end
