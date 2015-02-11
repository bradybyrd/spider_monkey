// |BMC TPS Info    |Facebox    |TPSDR0033624   |DR4U1.1.2.00   |http://defunkt.io/facebox/ |Registered |
$.facebox.settings.closeImage = url_prefix + '/facebox/dialogClose-whiteX.png';
var preViewWin = null;
$(function() {
  $(document).bind('reveal.facebox', function() {
    if ($('#facebox').find('div.content.no_cancel').length)
      blankFaceboxCloseImage();
  });

  $(document).bind('close.facebox', function() {
      if ((preViewWin != null) && (typeof(preViewWin) == "object")){
        if (!preViewWin.closed){
          preViewWin.close();
        }
      }
    if ($('#facebox').find('div.content.refresh').length)
      StreamStep.reloadPage();
      
  });

  function blankFaceboxCloseImage() {
    var replacement = $('<div></div>');
    var close_link = $('#facebox a.close');
    replacement.css({ width: close_link.width(), height: close_link.height() + 7 });
    close_link.replaceWith(replacement);
  }
});

