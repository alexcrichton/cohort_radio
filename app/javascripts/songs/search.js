//= require <pagination>
//= require <jquery/form>

$(function() {
  if($('#songs-search').length == 0) return;
  
  $('#songs-search form').ajaxForm({
    beforeSubmit: function() {
      $('#search-response').html($['huge-ajax']);
    },
    success: function(data) {
      $('#search-response').html($(data).filter('#search-response').html());
    }
  });
});
