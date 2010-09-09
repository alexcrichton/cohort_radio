//= require <jquery>
//= require <rails>

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
