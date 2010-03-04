var smallAjax = '<img src="/images/ajax-small.gif" alt="Loading..." class="loading"/>';
var bigAjax = '<img src="/images/ajax-big.gif" alt="Loading..." class="loading"/>';
var hugeAjax = '<div style="text-align:center"><img src="/images/ajax-huge.gif" alt="Loading..." class="loading"/></div>';

$.ajaxSetup({error: error});

$(function() {
  $('.tabs').tabs();
  $(".tabs").bind("tabsshow", function(event, ui) { 
    window.location.hash = ui.tab.hash;
  });
});

$(function() {
  $('#comments > .links .add, #comments > .links .cancel').click(function(){
    $(this).parents('.links').children().toggle();
    return false;
  });
  
  $('#comments > .links form').ajaxForm({
    beforeSubmit: function() {
      $(smallAjax).insertAfter($('#comments > .links form input[type=submit]').attr('disabled', 'disabled'));
    },
    success: function(data) {
      var form = $(data);
      form.find('form').bindCommentForm();
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
    return false;
  });
  $('.inline-edit form').bindInlineForm();
});

$.fn.extend({
  bindInlineForm: function() {
    $(this).ajaxForm({
      beforeSubmit: function(args, form) {
        var par = form.parents('.inline-edit');
        par.html(par.is('.mini') ? bigAjax : hugeAjax);
      },
      success: function(data) {
        var img = $('img.loading');
        var par = img.parents('.inline-edit');
        img.remove();
        var el = $(data);
        el.find('form').bindInlineForm();
        par.replaceWith(el);
      }
    })
  }
});

$(function() {
  $('a.remote-remove').live('click', function() {
    var img = $(smallAjax);
    var par = parent($(this), img, 'remove');
    $.ajax({
      type: $(this).is('.get') ? 'GET' : 'DELETE',
      url: $(this).attr('href'), 
      success: function(data) {
        par.remove();
      }
    });
    $(this).replaceWith(img);
    return false;
  });
  $('a.remote-replace').live('click', function() {
    var img = $(smallAjax);
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
  var par = link.parents('.' + klass + ':first')
  if(href.indexOf('#') >= 0)
    par = link.parents(href.substring(href.indexOf('#')) + ":first");
  if (par.length == 0)
    par = image;
  return par;
}

$(function() {
  $('.pagination-container .pagination a').live('click', function() {
    window.location.hash = '#' + $(this).attr('href');
    $(this).parents('.pagination-container:first').html(hugeAjax).load($(this).attr('href'));
    return false;
  });
  
  if (window.location.hash == '' || $('.pagination a').length == 0) return;
  
  $('.pagination-container:first').html(hugeAjax).load(window.location.hash.substring(1));
  
});

$(function() {
  if($('#songs-search').length == 0) return;
  
  $('#songs-search form').ajaxForm({
    beforeSubmit: function() {
      $('#search-response').html(hugeAjax);
    },
    success: function(data) {
      $('#search-response').html(data);
    }
  });
});

$(function(){
  if($('#fargo-search').length == 0) return;
  
  var timeoutId;
  
  $('#fargo-search form').ajaxForm({
    success: function() {
      $('#query').text($('#q').val());
      $('#search-response').html(hugeAjax);
      $('#q, input[type=submit]').attr('disabled', 'disabled');
      if(timeoutId != null) clearTimeout(timeoutId);
      timeoutId = setTimeout(function(){ 
        $('#search-response').load("/fargo/search/results?q=" + escape($('#q').val()), function(){
          $('#q, input[type=submit]').removeAttr('disabled');
          $('#search .result').bindSearchForms();
        });
      }, 1000)
    }
  });
});

$.fn.extend({
  bindSearchForms: function() {
    $(this).find("form").ajaxForm({
      beforeSubmit: function(args, form){
        $(form).find('input[type=submit]').replaceWith(smallAjax);      
      },
      success: function(data) {
        $('img.loading').replaceWith(data);
      }
    });
    return $(this);
  }
});

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

$(function() {
  $('#search .result').bindSearchForms();

  $("#song-search #q").autocomplete('/songs/search', {
    matchContains: true,
    extraParams: {
      playlist_id:$('.search #playlist_id').attr('value'),
      completion:'true',
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

function error() {
  $('.ui-dialog-content').dialog('close');
  $('img.loading').remove();
  $('<p>Server Error... Please Try later</p>').dialog({
    modal:true,
    close: function() {
      $('.ui-dialog').remove();
    }
  });
}

$(function() {
  if ($('#activations').length == 0) return;
  // send activation email
  $('#pending a.activate').live('click', function() {
    var span = $(this).parent();
    span.html(smallAjax);
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
    parent.html(smallAjax);
    parent.parents('form').ajaxSubmit({
      success: function(response) {
        if (!response.match(/error/)) {
          $.get('/activation/form/' + response, {form:other}, function(response) {
            parent.parents('tr').fadeOut(function() {
              $(this).remove();
            });
            $('#' + other).append($(response).hide().fadeIn()).parents('#activations');
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
    $(this).next('span').html(smallAjax).parents('form').ajaxSubmit({
      target: $(this).next('span')
    });
  });
});

function err(span) {
  span.html('error').css('color', 'red');
}


