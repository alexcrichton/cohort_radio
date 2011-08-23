//= require pipe
//= require songs/show

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

  $.pipe.bind('playlist.removed_item', function(data) {
    if (data.playlist_id == playlist_id) {
      $('.song[data-queue-id=' + data.queue_id + ']').slideUp(function() {
        $(this).remove();
      });
    }
  });

  $.pipe.bind('playlist.playing', function(data) {
    if (data.playlist_id == playlist_id) {
      $('#current-song').text(data.song);
    }
  });

  $.pipe.bind('playlist.added_item', function(data) {
    if (data.playlist_id == playlist_id) {
      $('#songs').load(data.url + ' #songs');
    }
  });

  $.pipe.bind('playlist.queue_removed', function(data) {
    if (data.playlist_id == playlist_id) {
      $('.song[data-queue-id=' + data.queue_id + ']').slideUp(function() {
        $(this).remove();
      });
    }
  });
});
