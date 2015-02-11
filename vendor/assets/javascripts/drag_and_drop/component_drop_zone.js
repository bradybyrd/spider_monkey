////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(document).ready(function() {
  $('.installed_components').livequery( function() { $(this).componentDropZone();});
});

$.fn.extend({

  componentDropZone: function() {
    return this.droppable({
      accept: '.application_component',
      hoverClass: 'hover',
      drop: function(e, ui) {
        var appEnvId = $(this).attr('id').match(/\d+/);
        if (!$('#installed_components_list_' + appEnvId + ' tr').hasClass(ui.helper.attr('id'))) {
          ui.helper.remove(); // don't show snap-back animation

          $('#new_installed_component_' + appEnvId).ajaxSubmit({
            data: {"installed_component[application_component_id]": ui.draggable.attr('id').match(/application_component_(\d+)/)[1]},
            success: function(html) {
              $('#installed_components_list_' + appEnvId).parents('.application_environment_row').html(html);
              $('#installed_components_' + appEnvId + '.installed_components tr.empty').remove();
            }
          })
        }
      }
    })
  }

});
