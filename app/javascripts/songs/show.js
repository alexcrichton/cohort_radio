//= require <jquery>
//= require <rails>
//= require <pipe>

$(function() {
  $('.song .ratings .user li').live('hover', function() {
    $(this).addClass('selected');
    var num = $(this).nextAll().addClass('selected').length + 1;
    $(this).parents('.rating').find('.score').text(num);
    $(this).prevAll().removeClass('selected');
  }).live('click', function() {
    $.railsPut({
      url: $(this).parents('.ratings').attr('remote'),
      data: {rating: {
        score: $(this).parents('ul').find('li.selected').length
      }}
    });
  });

  $('.song .ratings .rating').live('mouseout', function() {
    var num = parseInt($(this).find('ul').attr('data-rating'), 10);
    var li = $(this).find('li:eq(' + (10 - num) + ')');
    li.addClass('selected');
    li.nextAll().addClass('selected');
    li.prevAll().removeClass('selected');

    $(this).find('.score').text(num);
  });
});

$.pipe.bind('song.destroyed', function(data) {
  $('#s' + data.song_id).slideUp(function() {
    $(this).remove();
  });
});

$.pipe.bind('song.updated', function(data) {
  if ($('#s' + data.song_id).length > 0) {
    $.ajax({
      url: data.url,
      dataType: 'script'
    });
  }
});

$.pipe.bind('song.rating', function(data) {
  $('#s' + data.song_id + ' .rating .overall li').each(function(i, el) {
    if (i >= 10 - data.rating) {
      $(el).addClass('selected');
    } else {
      $(el).removeClass('selected');
    }
  });

  $('#s' + data.song_id + ' .rating .overall.score').text(data.rating);
});
