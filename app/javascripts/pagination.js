//= require <jquery>

$(function() {
  $('.pagination-container .pagination a').live('click', function() {
    window.location.hash = '#' + $(this).attr('href');
    $(this).parents('.pagination-container:first').html(
      $['huge-ajax']).load($(this).attr('href'));
    return false;
  });
  
  if (window.location.hash == '' || $('.pagination a').length == 0) return;
  
  $('.pagination-container:first').html(
    $['huge-ajax']).load(window.location.hash.substring(1));
  
});
