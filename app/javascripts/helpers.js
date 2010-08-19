//= require <jquery>
//= require <jquery/form>

$(function() {
  $('#comments > .links .add, #comments > .links .cancel').click(function() {
    $(this).parents('.links').children().toggle();
    return false;
  });
  
  $('#comments > .links form').ajaxForm({
    beforeSubmit: function() {
      $($['small-ajax']).insertAfter($('#comments > .links form input[type=submit]').attr('disabled', 'disabled'));
    },
    success: function(data) {
      var form = $(data);
      form.find('form').bindInlineForm();
      form.insertAfter('#comments > .links');
      $('img.loading').remove();
      $('#comments > .links form').parent().hide().prev().show();
      $('#comments > .links form input[type=submit]').removeAttr('disabled');
    },
    resetForm: true
  });
});

$(function() {
  $('.inline-edit a.edit, .inline-edit form a.cancel').live('click', function() {
    var par = $(this).parents('.inline-edit:first');
    par.find('a.edit, a.cancel').toggle();
    par.children('.content, .form').toggle();
    if ($(this).is('.edit'))
      par.find('form input[type=text]:first').focus();
    return false;
  });
  $('.inline-edit form').bindInlineForm();
});

$.fn.extend({
  bindInlineForm: function() {
    $(this).ajaxForm({
      beforeSubmit: function(args, form) {
        var par = form.parents('.inline-edit');
        par.html(par.is('.mini') ? $['big-ajax'] : $['huge-ajax']);
      },
      success: function(data) {
        var img = $('img.loading');
        var par = img.parents('.inline-edit');
        img.remove();
        var el = $(data);
        el.find('form').bindInlineForm();
        par.replaceWith(el);
      }
    });
  }
});

$(function() {
  $('a.remote-remove').live('click', function() {
    var img = $($['small-ajax']);
    var par = parent($(this), img, 'remove');
    $.ajax({
      type: $(this).is('.get') ? 'GET' : 'DELETE',
      url: $(this).attr('href'), 
      success: function(data) {
        par.slideUp(function(){
          par.remove();
        });
      }
    });
    $(this).replaceWith(img);
    return false;
  });
  $('a.remote-replace').live('click', function() {
    var img = $($['small-ajax']);
    var par = parent($(this), img, 'replace');
    $.ajax({
      url: $(this).attr('href'), 
      success: function(data) {
        par.replaceWith(data);
      }
    });
    $(this).replaceWith(img);
    return false;
  });
});

function parent(link, image, klass) {
  var href = link.attr('href');
  var par = link.parents('.' + klass + ':first');
  if(href.indexOf('#') >= 0)
    par = link.parents(href.substring(href.indexOf('#')) + ":first");
  if (par.length == 0)
    par = image;
  return par;
}
