// This file is the property of StreamStep, Inc.
// The contents of this file are covered by Copyright by StreamStep, Inc.
// Any unauthorized and unlicensed use is strictly prohibited.
// The software source code can be used only with a valid software license from StreamStep, Inc.
// In NO WAY is this software open source, free, or in the public domain.

$(document).ready(function() {
  $('.step_phase:not(.frozen) .step:not(.procedure, .completed_step)').livequery( function() { $(this).draggableObject(false).find('form');});
  $('#sidebar .procedure').livequery( function() { $(this).draggableObject(false);});

  $('.procedure_step_phase:not(.frozen) .procedure_step:not(.completed_step)').livequery( function() { $(this).draggableObject(false).find('form');});
  $('.component_level .component').livequery( function() { $(this).draggableObject(false).find('form');});
  $('.environment_level .environment').livequery( function() { $(this).draggableObject(false).find('form');});
  $('.route_gate_level .route_gate').livequery( function() { $(this).draggableObject(false).find('form');});
  $('.plan_member_level .plan_member').livequery( function() { $(this).draggableObject(false).find('form');});

  $('span.application_component').livequery( function() { $(this).draggableObject(true);});
  $('span.work_task').livequery( function() { $(this).draggableObject(true);});
  $('span.environment_type').livequery( function() { $(this).draggableObject(true);});
  $('span.phase').livequery( function() { $(this).draggableObject(true);});
  $('span.runtime_phase').livequery( function() { $(this).draggableObject(true);});

  $('span.package_content').livequery( function() { $(this).draggableObject(true);});
  $('span.release').livequery( function() { $(this).draggableObject(true);});
  $('span.property').livequery( function() { $(this).draggableObject(true);});
	$('span.preference').livequery( function() { $(this).draggableObject(true);});
  $('span.plan_stage').livequery( function() { $(this).draggableObject(true);});
  $('span.plan').livequery( function() { $(this).draggableObject(true);});
});

$.fn.extend({

  draggableObject: function(use_revert) {
      
    return this.draggable({
      helper: 'clone',
      revert: use_revert,
      revertDuration: 0,
      start: function(e, ui) { 
        $(this).addClass('dragging');
        ui.helper.addClass('helping');
      },
      stop: function(e, ui) {
         
        $(this).removeClass('dragging');
        ui.helper.removeClass('helping');
      },
      drag: function(e, ui) {
        
        if (e.clientY < 0) {
          $(window).scrollTop($(window).scrollTop() - 20)
        } else if (e.clientY > $(window).height()) {
          $(window).scrollTop($(window).scrollTop() + 20);
        }
      }
    });
  }

});
