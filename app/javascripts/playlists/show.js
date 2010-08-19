//= require <jquery/form>
//= require <jquery/autocomplete>

$.fn.extend({
  bindSearchForms: function() {
    $(this).find("form").ajaxForm({
      beforeSubmit: function(args, form){
        $(form).find('input[type=submit]').replaceWith($['small-ajax']);      
      },
      success: function(data) {
        $('img.loading').replaceWith(data);
      }
    });
    return $(this);
  }
});

$(function() {
  $('#search .result').bindSearchForms();

  $("#song-search #q").autocomplete('/songs/search', {
    matchContains: true,
    extraParams: {
      playlist_id:$('.search #playlist_id').attr('value'),
      completion:'true'
    },
    cacheLength: 50,
    formatItem: function(row) {
      return row[0].replace(/\(\d+\)/, '');
    },
    formatResult: function(arr) {
      return arr[0].replace(/<img.*?\/>\s*/, '').replace(/\s*\(\d+\)$/, '');
    }
  }).result(function(event, data, formatted) {
    var id = formatted.match(/\((\d+)\)/)[1];
    $('<input type="hidden" value="' + id + '" name="song_id" />').insertAfter($(this));
  });
});
