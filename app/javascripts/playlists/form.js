//= require <jquery/autocomplete>

$(function() {
  $("#memberships form #q").autocomplete('/users/search', {
    matchContains: true,
    cacheLength: 50,
    formatItem: function(row) {
      return row[0].replace(/\(\d+\)/, '');
    },
    formatResult: function(arr) {
      return arr[0].replace(/&.*$/, '');
    }
  }).result(function(event, data, formatted) {
    var id = formatted.match(/\((\d+)\)/)[1];
    $('<input type="hidden" value="' + id + '" name="user_id" />').insertAfter($(this));
  });  
});
