//= require <jquery/core>
//= require <jquery/ui>

$.ajaxSetup({error: error});

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

$['small-ajax'] = "<img alt=\"Ajax-small\" class=\"loading\" src=\"/images/ajax-small.gif?1271485846\" />";
$['big-ajax'] = "<img alt=\"Ajax-big\" class=\"loading\" src=\"/images/ajax-big.gif?1271485860\" />";
$['huge-ajax'] = "<img alt=\"Ajax-huge\" class=\"loading\" src=\"/images/ajax-huge.gif?1271485827\" />";
