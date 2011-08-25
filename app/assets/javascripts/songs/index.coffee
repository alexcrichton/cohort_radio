channel = pusher.subscribe 'song'

channel.bind 'destroyed', (data) ->
  $('.song[data-id=' + data.id + ']').slideUp -> $(this).remove()

channel.bind 'updated', (data) ->
  song = $('.song[data-id=' + data.song_id + ']')
  return if song.length == 0
  $.get data.url + '.js'
