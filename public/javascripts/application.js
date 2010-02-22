var smallAjax = '<img src="/images/ajax-small.gif" alt="Loading..." class="loading"/>';
var bigAjax = '<img src="/images/ajax-big.gif" alt="Loading..." class="loading"/>';
var hugeAjax = '<img src="/images/ajax-huge.gif" alt="Loading..." class="loading"/>';

$(function(){
  $('.tabs').tabs();
});

$(function() {
  if($('#songs-search').length == 0) return;
  
  $('#songs-search form').ajaxForm({
    beforeSubmit: function(){
      $('#search-holder').show();
      $('#search-response').hide();
    },
    success: function(data){
      $('#search-response').html(data).show();
      $('#search-holder').hide();
    },
    error: error
  })
});

$(function(){
  if($('#fargo-search').length == 0) return;
  
  var timeoutId;
  
  $('#fargo-search form').ajaxForm({
    error: error,
    success: function() {
      $('#query').text($('#q').val());
      $('#search-holder').show();
      $('#search-response').hide();
      $('#q, input[type=submit]').attr('disabled', 'disabled');
      if(timeoutId != null) clearTimeout(timeoutId);
      timeoutId = setTimeout(function(){ 
        $('#search-response').load("/fargo/search/results?q=" + escape($('#q').val()), function(){
          $('#search-holder').hide();
          $('#search-response').show();
          $('#q, input[type=submit]').removeAttr('disabled');
          $('#search .result').bindSearchForms();
          
        });
      }, 2000)
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
        },
        error: error
      })
      return false;
  });
  
  $('#connections .disconnect').click(function(){
    var el = $(this).parents('tr');
    $(this).replaceWith(smallAjax);
      $.ajax({
        url: $(this).attr('href'),
        success: function(){
          el.remove();
        }, 
        error: error
      })
      return false;
  });
  // $('#downloads .download a.remove').click(function(){
  //   var el = $(this).parents('.download');
  //   $(this).replaceWith(smallAjax);
  //   $.ajax({
  //     type: 'DELETE',
  //     url: $(this).attr('href'),
  //     success: function(){
  //       el.remove();
  //     }
  //   })
  //   return false;
  // });
  // $('#downloads .download a.retry').click(function(){
  //   var el;
  //   $(this).replaceWith(el = $(smallAjax));
  //   $.ajax({
  //     url: $(this).attr('href'),
  //     success: function(data){
  //       el.replaceWith(data);
  //     }
  //   })
  //   return false;
  // });
});

$.fn.extend({
  bindSearchForms: function() {
    $(this).find("form").ajaxForm({
      beforeSubmit: function(args, form){
        $(form).find('input[type=submit]').replaceWith(smallAjax);      
      },
      error: error,
      success: function(data) {
        $('img.loading').replaceWith(data);
      }
    });
    return $(this);
  }
});

$(function() {
  $('#search .result').bindSearchForms();
});

$(function(){
  $("#song-search #q").autocomplete('/songs/search', {
    matchContains: true,
    extraParams: {
      playlist_id:$('.search #playlist_id').attr('value'),
      completion:'true',
    },
    cacheLength: 50,
    // multiple: false,
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
  $('img.loading').remove();
  alert('Server Error... Please try later');
}

$(function() {
  if ($('#activations').length == 0) return;
  // send activation email
  $('#pending a').live('click', function() {
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
