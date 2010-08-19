//= require <jquery/form>

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

$(function(){
  if($('#fargo-search').length == 0) return;
  
  var timeoutId;
  
  $('#fargo-search form').ajaxForm({
    success: function() {
      $('#query').text($('#q').val());
      $('#search-response').html($['huge-ajax']);
      $('#q, input[type=submit]').attr('disabled', 'disabled');
      if(timeoutId != null) clearTimeout(timeoutId);
      timeoutId = setTimeout(function(){ 
        $('#search-response').load("/fargo/search/results?q=" + escape($('#q').val()), function(){
          $('#q, input[type=submit]').removeAttr('disabled');
          $('#search .result').bindSearchForms();
        });
      }, 1000);
    }
  });
});
