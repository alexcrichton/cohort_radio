$(function() {
  $("#memberships form #q").autocomplete({
    minLength: 2,
    source: function(request, response) {
      $.get('/users/search.json', {q:request.term}, function(data) {
        response(data);
      });
    },
    select: function(event, ui) {
      $(this).prev('input:hidden').val(ui.item.id);
      $(this).val(ui.item.name);
      return false;
    },
    focus: function(event, ui) {
      $(this).val(ui.item.name);
      return false;
    }
  }).data('autocomplete')._renderItem = function(ul, item) {
    return $('<li/>').data('item.autocomplete', item)
              .append('<a>' + item.name + '</a>')
              .appendTo(ul);
  };
});
