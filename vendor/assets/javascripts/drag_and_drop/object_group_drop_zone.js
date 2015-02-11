// This file is the property of StreamStep, Inc.
// The contents of this file are covered by Copyright by StreamStep, Inc.
// Any unauthorized and unlicensed use is strictly prohibited.
// The software source code can be used only with a valid software license from StreamStep, Inc.
// In NO WAY is this software open source, free, or in the public domain.

$(document).ready(function() {
  $('.step_phase:not(.frozen), .step_phase_divider:not(.frozen)').livequery( function() { $(this).objectGroupDropZone('step', 'phase');});

  $('.procedure_step_phase:not(.frozen), .procedure_step_phase_divider:not(.frozen)').livequery( function() { $(this).objectGroupDropZone('procedure_step', 'phase');});

  $('.component_level, .component_level_divider').livequery( function() { $(this).objectGroupDropZone('component', 'level');});

  $('.environment_level, .environment_level_divider').livequery( function() { $(this).objectGroupDropZone('environment', 'level');});

  $('.route_gate_level, .route_gate_level_divider').livequery( function() { $(this).objectGroupDropZone('route_gate', 'level');});
  
  $('.plan_member_level, .plan_member_level_divider').livequery( function() { $(this).objectGroupDropZone('plan_member', 'level');});

  $('.property_level, .property_level_divider').livequery( function() { $(this).objectGroupDropZone('property', 'level');});
});

$.fn.extend({

  objectGroupDropZone: function(objectType, groupName) {
    return this.droppable({
      accept: '.' + objectType,
      hoverClass: 'hover',
      tolerance: 'pointer',
      drop: function(e, ui) {
        var drop = $(this);
        var objectWithGroupName = objectType + '_' + groupName;

        if (drop.hasClass(objectWithGroupName + '_divider')) {
          // create a new object group div by cloning an existing one, clearing existing objects, and surround it with dividers
          var newObjectGroup = $('.' + objectWithGroupName).eq(0).clone().children('.' + objectType).remove().end().removeClass('frozen');
          drop.after(drop.clone()).after(newObjectGroup);

          // newly inserted elements need droppable functionality
          drop.next().objectGroupDropZone(objectType, groupName).next().objectGroupDropZone(objectType, groupName);

          // ensure that the new object group gets the moved object
          drop = newObjectGroup;
        }

        // if we're moving the first object out of this group, update the different_level_from_previous flag for the next one
        if (ui.draggable.parents('div.' + objectWithGroupName).length > 0 && ui.draggable.prev('div.' + objectType).length == 0) {
          var params = {};
          params[objectType + '[different_level_from_previous]'] = true;
          ui.draggable.next().filterDraggables().saveObjectPosition(objectType, groupName, ui.draggable, drop, params, true);
        }

        ui.draggable.saveObjectPosition(objectType, groupName, ui.draggable, drop);

        // renumber the levels, if necessary
        $('div.level_number').each( function(i) {
          $(this).html(i + 1);
        });
      }
    });
  },

  saveObjectPosition: function(objectType, groupName, drag, drop, params, no_move) {
    var objectsInPreviousLevels = drop.prevAll('.' + objectType + '_' + groupName).find('.' + objectType).filterDraggables();
    var previousObjectsInCurrentLevel = drop.children('.' + objectType).filterDraggables();
    
    if (!params) {
      var insertionParam = objectType + '[insertion_point]';
      var rowParam = objectType + '[different_level_from_previous]';

      var params = {};
      params[insertionParam] = objectsInPreviousLevels.length + previousObjectsInCurrentLevel.length + 1;
      params[rowParam] = (previousObjectsInCurrentLevel.length == 0);
    }

    this.find('form').ajaxSubmit({
      data: params, 
      success: function(html) {
        if (!no_move) {
          drop.append(html)
          var newObj = drop.children('div:last');
          newObj.removeClass(newObj.attr('class').match(/component_color_\d+/)[0]);
          if (!drag.hasClass('create_new_on_drop')) {
            removeDropGroupIfEmpty(drag, objectType);

            newObj.addClass(drag.attr('class').match(/component_color_\d+/)[0]);
            newObj.find("span.step_number").html(drag.find('span.step_number'));
            drag.remove();
          } else {

            var similar_divs = draggableObjectsOfSameComponentClass(newObj, objectType)
            if (similar_divs.length > 0) {
              newObj.addClass($(similar_divs[0]).attr('class').match(/component_color_\d+/)[0]);
            } else {
              var nextClass = "component_color_" + (arrayMax(usedComponentColorClassNumbers('.' + objectType)) + 1);
              newObj.addClass(nextClass);
            }
            newObj.find("span.step_number").html('*NEW*');
          }
        }
      }
    });
  }
  
});

