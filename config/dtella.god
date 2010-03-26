God.watch do |w|
  w.name = "dtella"
  w.group = 'cradio'
  
  w.interval = 30.seconds # default      
  w.start = "/etc/rc.d/dtella start"
  w.stop = "/etc/rc.d/dtella stop"
  w.restart = "/etc/rc.d/dtella restart"
  w.start_grace = 20.seconds
  w.restart_grace = 20.seconds
  
  w.pid_file = "/var/run/dtella.pid"

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 15.percent
      c.times = [3, 5] # 3 out of 5 intervals
    end
  end

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end


end
