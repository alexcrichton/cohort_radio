//= require <jquery/rails>

$.extend($, {
  railsPut: function(config) {
    var csrf_token = $('meta[name=csrf-token]').attr('content'),
        csrf_param = $('meta[name=csrf-param]').attr('content');

    if (!config.data) config.data = {};
    config.data[csrf_param] = csrf_token;
    config.type = 'PUT';
    config.dataType = 'script';

    $.ajax(config);
  }
});

$(function() {
  $('a[data-remote]').live('ajax:loading', function () {
    $($['small-ajax']).insertAfter(this);
  });

  $('a[data-remote]').live('ajax:success ajax:complete ajax:failure', function () {
    $(this).next('img.loading').remove();
  });
});
