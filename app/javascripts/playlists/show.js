//= require <jquery/ui>

$(function() {
  var query = $("#song-search #q");
  var playlist_id = $('.status').attr('data-id');
  if (query.length > 0) {
    query.autocomplete({
      minLength: 2,
      source: function(request, response) {
        $.get('/songs/search.json',
          {q:request.term, completion:'true',
            playlist_id: playlist_id},
        function(data) {
          response(data);
        });
      },
      select: function(event, ui) {
        $(this).prev('input:hidden').val(ui.item.value);
        $(this).val(ui.item.title);
        return false;
      },
      focus: function(event, ui) {
        $(this).val(ui.item.title);
        return false;
      }
    }).data('autocomplete')._renderItem = function(ul, item) {
      return $('<li/>').data('item.autocomplete', item)
                .append('<a>' + item.image + " " + item.title + " - " +
                        item.artist + '</a>')
                .appendTo(ul);
    };
  }

  var ws = new WebSocket('ws://localhost:8080');

  ws.onmessage = function(event) {
    var data = JSON.parse(event.data);

    if (data.playlist_id != playlist_id) {
      return;
    }

    if (data.type == 'playlist.removed_item') {
      console.log('.song[data-queue-id=' + data.queue_id + ']');
      $('.song[data-queue-id=' + data.queue_id + ']').slideUp(function() {
        $(this).remove();
      });
    } else if (data.type == 'playlist.added_item') {
      $('#songs').replaceWith(data.html);
    }
  };
});
