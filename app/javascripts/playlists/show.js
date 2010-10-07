//= require <jquery/ui>

$(function() {
  $("#song-search #q").autocomplete({
    minLength: 2,
    source: function(request, response) {
      $.get('/songs/search.json',
        {q:request.term, completion:'true',
          playlist_id: $('.search #playlist_id').attr('value')},
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
});
