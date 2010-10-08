//= require <jquery>

$.pipe = $('<div/>').hide();

$(function() {
  $(document.body).append($.pipe);

  var ws = new WebSocket('ws://' + window.location.hostname + ':8080');
  ws.onmessage = function(event) {
    $.pipe.trigger(JSON.parse(event.data));
  };
});
