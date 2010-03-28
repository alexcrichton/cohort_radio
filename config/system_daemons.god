%w{icecast dtella}.each do |daemon|
  God.watch do |w|
    w.name = daemon
  
    w.interval = 30.seconds # default      
  
    if daemon == 'dtella'
      w.start = "dtella"
      w.stop  = "dtella --terminate"
    else
      w.start = "/usr/bin/icecast -c /etc/icecast.xml"
    end
    w.group = 'cradio'
  
    w.transition(:init, true => :up, false => :start) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

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

    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end
