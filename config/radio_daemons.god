rails_root = "/srv/http/cohort_radio/current"

%w{radio delayed_job fargo}.each do |daemon|
  God.watch do |w|

    w.name  = "cradio-#{daemon}"
    w.group = "cradio"
    w.interval = 30.seconds # default      
  
    w.start   = "cd #{rails_root}; RAILS_ENV=production script/#{daemon} start"
    w.stop    = "cd #{rails_root}; RAILS_ENV=production script/#{daemon} stop"
    w.restart = "cd #{rails_root}; RAILS_ENV=production script/#{daemon} restart"
  
    w.pid_file = File.join(rails_root, "tmp/pids/#{daemon}.pid")
  
    w.behavior(:clean_pid_file)
  
    w.uid = 'capistrano'
    w.gid = 'http'
  
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