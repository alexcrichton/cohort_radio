//= require <jquery/ui>

$(function() {
  $('.tabs').tabs().bind('tabsshow', function(event, ui) {
    window.location.hash = ui.tab.hash;
  });
});
