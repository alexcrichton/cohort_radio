window.humanize_bytes = (bytes) ->
  suffix = 'B'
  stop = false
  while bytes > 1024 && !stop
    bytes /= 1024
    switch suffix
      when  'B' then suffix = 'KB'
      when 'KB' then suffix = 'MB'
      when 'MB' then suffix = 'GB'
      when 'GB' then suffix = 'TB'
      when 'TB' then stop = true

  bytes = parseInt bytes * 100, 10
  bytes /= 100.0
  bytes + ' ' + suffix
