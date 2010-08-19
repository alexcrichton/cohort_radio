//= require <jquery>

$(function() {
  $('.song .ratings .user li').live('hover', function() {
    $(this).addClass('selected');
    $(this).nextAll().addClass('selected');
    $(this).prevAll().removeClass('selected');
  }).live('click', function() {
    $(this).parents('.song').load($(this).parents('.ratings').attr('remote') + ' .song',
    {
      rating: {
        score: $(this).parents('ul').find('li.selected').length
      }
    });
  });
});
