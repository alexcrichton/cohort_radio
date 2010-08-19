//= require <jquery>

$(function() {
  if ($('#activations').length == 0) return;
  // send activation email
  $('#pending a.activate').live('click', function() {
    var span = $(this).parent();
    span.html($['small-ajax']);
    span.parents('form').ajaxSubmit({
      success: function(response, text) {
        if (response.match(/error/))
          err(span);
        else
          span.parents('td').html($('<span>success</span>').css('color', 'green'));
      }
    });
    return false;
  });

  $('#activated form a, #confirmed form a').live('click', function() {
    var other = $(this).parents('#confirmed').length == 0 ? 'confirmed' : 'activated';
    var parent = $(this).parent();
    parent.html($['small-ajax']);
    parent.parents('form').ajaxSubmit({
      success: function(response) {
        if (!response.match(/error/)) {
          $.get('/activation/form/' + response, {form:other}, function(response) {
            parent.parents('tr').fadeOut(function() {
              $(this).remove();
            });
            $('#' + other).append(
              $(response).hide().fadeIn()).parents('#activations');
          });
        } else {
          err(element);
        }
      }
    });
    
    return false;
  });
  // adminize the user
  $('#confirmed input:checkbox').live('click', function() {
    $(this).next('span').html($['small-ajax']).parents('form').ajaxSubmit({
      target: $(this).next('span')
    });
  });
});

function err(span) {
  span.html('error').css('color', 'red');
}
