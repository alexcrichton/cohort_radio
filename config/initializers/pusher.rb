uri = URI.parse(ENV['PUSHER_URL'] || '')

Pusher.app_id = (uri.path.match(/\d+/) || '5975').to_s
Pusher.key    = uri.user || '60ad04716e80aa8eae65'
Pusher.secret = uri.password || '03216805993e774c89bc'
