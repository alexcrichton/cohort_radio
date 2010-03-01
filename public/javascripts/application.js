var smallAjax = '<img src="/images/ajax-small.gif" alt="Loading..." class="loading"/>';
var bigAjax = '<img src="/images/ajax-big.gif" alt="Loading..." class="loading"/>';
var hugeAjax = '<div style="text-align:center"><img src="/images/ajax-huge.gif" alt="Loading..." class="loading"/></div>';

$.ajaxSetup({error: error});

$(function() {
  $('.tabs').tabs();
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
  
  $('#comments .comment .edit, #comments .comment .cancel').live('click', function() {
    var par = $(this).parents('.comment');
    par.find('.content, .form').toggle();
    return false;
  });
  
  $('#comments .comment form').bindCommentForm();
  
  $('.comment .links .remove').live('click', function() {
    var par = $(this).parents('.comment');
    $.ajax({
      type: 'DELETE',
      url: $(this).attr('href'),
      success: function() {
        par.remove();
      }
    });
    $(this).replaceWith(smallAjax);
    return false;
  });
  
});

$.fn.extend({
  bindCommentForm: function() {
    $(this).ajaxForm({
      beforeSubmit: function(args, form) {
        $(smallAjax).insertAfter(form.find('input[type=submit]').attr('disabled', 'disabled'));
      },
      success: function(data) {
        var form = $('img.loading').parents('form');
        form.find('img.loading').remove();
        form.find('input[type=submit]').removeAttr('disabled');
        var newform = $(data);
        newform.find('form').bindCommentForm();
        form.parents('.comment').replaceWith(newform);
      },
      resetForm: true
    });
  }
});

$(function() {
  $('.song .links .remove, .song .pool-remove').live('click', function() {
    var par = $(this).parents('.song');
    $.ajax({
      type: $(this).is('.pool-remove') ? 'GET' : 'DELETE',
      url: $(this).attr('href'),
      success: function() {
        par.remove();
      }
    });
    $(this).replaceWith(smallAjax);
    return false;
  });
});

$(function() {
  $('.song .add ul li a').live('click', function() {
    var par = $(this).parents('li:first');

    $.ajax({
      url: $(this).attr('href'),
      success: function(data) {
        par.html(data);
      }
    });
    
    par.html(smallAjax);
    
    return false;
  });
});

$(function() {
  $('#radio-status .links a').live('click', function(){
    var par = $(this).parents('tr');
    $.ajax({
      url: $(this).attr('href'), 
      success: function(data) {
        par.replaceWith(data);
      }
    });
    $(this).replaceWith(smallAjax);
    return false;
  });
});

$(function() {
  $('.pagination-container .pagination a').live('click', function() {
    $(this).parents('.pagination-container:first').html(hugeAjax).load($(this).attr('href'));
    return false;
  });
});

$(function() {
  if($('#songs-search').length == 0) return;
  
  $('#songs-search form').ajaxForm({
    beforeSubmit: function() {
      $('#search-holder, #search-response').toggle();
    },
    success: function(data) {
      $('#search-response').html(data).show();
      $('#search-holder').hide();
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

$(function() {
  $('#waiting .links .remove').click(function(){
    var el = $(this).parents('.download');
    $(this).replaceWith(smallAjax);
    $.ajax({
      url: $(this).attr('href'),
      success: function(){
        el.remove();
      }
    });
    return false;
  });
  
  $('#connections tr.timeout a').live('click', function(){
    var par = $(this).parents('td:first');
    $.ajax({
      url: $(this).attr('href'), 
      success: function(data) {
        par.html(data);
      }
    });
    $(this).html(smallAjax);
    return false;
  });
  
  $('#connections .disconnect, #failed tr a').click(function(){
    var el = $(this).parents('tr');
    $(this).replaceWith(smallAjax);
    $.ajax({
      url: $(this).attr('href'),
      success: function(){
        el.remove();
      }
    });
    return false;
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
  $('#memberships li a').live('click', function() {
    var par = $(this).parents('li');
    $.ajax({
      url: $(this).attr('href'),
      type: 'DELETE',
      success: function() {
        par.remove();
      }
    });
    $(this).replaceWith(smallAjax);
    return false;
  });
  $("#memberships form #q").autocomplete('/users/search', {
    matchContains: true,
    cacheLength: 50,
    formatItem: function(row) {
      return row[0].replace(/\(\d+\)/, '');
    },
    formatResult: function(arr) {
      return arr[0].replace(/\s*\(\d+\)$/, '');
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


