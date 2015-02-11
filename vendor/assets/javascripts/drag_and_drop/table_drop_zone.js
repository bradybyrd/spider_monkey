// This file is the property of StreamStep, Inc.
// The contents of this file are covered by Copyright by StreamStep, Inc.
// Any unauthorized and unlicensed use is strictly prohibited.
// The software source code can be used only with a valid software license from StreamStep, Inc.
// In NO WAY is this software open source, free, or in the public domain.

$(document).ready(function() {
  $('.environment_type_row').livequery( function() { $(this).tableDropZone('environment_type');});
  $('.work_task_row').livequery( function() { $(this).tableDropZone('work_task');});
  $('.phase_row').livequery( function() { $(this).tableDropZone('phase');});
  $('.runtime_phase_row').livequery( function() { $(this).tableDropZone('runtime_phase');});
  $('.package_content_row').livequery( function() { $(this).tableDropZone('package_content');});
  $('.release_row').livequery( function() { $(this).tableDropZone('release');});
  $('.property_row').livequery( function() { $(this).tableDropZoneWithPositions('property', 'properties');});
  $('.preference_row').livequery( function() { $(this).tableDropZone('preference', 'preferences');});
  $('.plan_stage_row').livequery( function() { $(this).tableDropZone('plan_stage');});
  $('.plan_row').livequery( function() { $(this).tableDropZone('plan','plans');});
});


$.fn.extend({

  tableDropZone: function(row_type, plural_row_type) {
    return this.droppable({
      accept: '.' + row_type,
      hoverClass: 'hover',
      drop: function(e, ui) {
        //ui.helper.hide(); // don't show snap-back animation
        dropZone = $(this);
        var rowIndex = ui.draggable.parents('tr').prevAll('tr.' + row_type + '_row').length + 1;
        var rowId = ui.draggable.attr('id').match(/\d+/)[0];
        var insertionPoint = dropZone.prevAll('tr.' + row_type + '_row').length + 1;
        if (!plural_row_type) plural_row_type = row_type + 's';
        var data_object = { id: rowId,  row_type: row_type};
        data_object[row_type + "[insertion_point]"] = insertionPoint;
        if (row_type == "plan") {
          plan_drag_drop(rowId,rowIndex,insertionPoint,ui,dropZone);
        } else {
          $('form#reorder_' + plural_row_type).ajaxSubmit({
            data: data_object,
            success: function(html){
              if (rowIndex > insertionPoint){
                dropZone.before(html);
              }else{
                 dropZone.after(html);
              }
              ui.draggable.parents('tr:first').remove();
            }
          })
        }
      }
    });
  }
});

$.fn.extend({
  tableDropZoneWithPositions: function(row_type, plural_row_type) {
    return this.droppable({
      accept: '.' + row_type,
      hoverClass: 'hover',
      drop: function(e, ui) {
        var rowId = ui.draggable.attr('id').match(/\d+/)[0];
        var insertionPoint = $(e.target).data('position');
        if (!plural_row_type) plural_row_type = row_type + 's';
        var data_object = { id: rowId,  row_type: row_type};
        data_object[row_type + "[insertion_point]"] = insertionPoint;
        $('form#reorder_' + plural_row_type).ajaxSubmit({
          data: data_object,
          success: function(html){
            $('.formatted_table').find('tbody').html(html);
          }
        })
      }
    });
  }
});


function plan_drag_drop(rowId,rowIndex,insertionPoint,ui,dropZone){
  var planId = $('#request_'+rowId).attr('plan_id');
  var currently_selected_run = $('#request_'+rowId).attr('data-selected-run-id');

  // find the member we dragged and (optionally) the member we landed on
  var memberToInsertId = $('#request_'+rowId).attr('data-member-id');
  var memberToTargetId = dropZone.find("#member_id").val();

  // get the stage id of the item being dragged
  var stageIdOfDraggedRequest = $("#request_row_" + rowId).parents("table:first").attr("table_stage_id")

  // try to find the stage id from the dropped on member
  // or set the stage_id to the parent stage of the table
  // if it was stage with no items
  var newStageId = dropZone.find("#stage_id").val();
  if(newStageId == "" || isNaN(newStageId) || dropZone.find('span').html() == "No Plan Items"){
    newStageId = dropZone.parents('.requestList').attr('table_stage_id');
  }

  //alert("planId: " + planId + " newStageId:" + newStageId + " memberToInsertId: " + memberToInsertId + " memberToTargetId: " + memberToTargetId + " stageIdOfDraggedRequest: " + stageIdOfDraggedRequest);

  //TODO: url prefix introduced on develop branch -- needs testing with plan drag and drop to confirm merge
  if (newStageId != "" && !isNaN(newStageId)) {
    $.ajax({
      url: url_prefix + "/plans/" + planId + "/reorder",
      type: "PUT",
      data: "new_stage_id=" + newStageId + "&member_to_insert_id=" + memberToInsertId + "&member_to_target_id=" + memberToTargetId + "&run_id=" + currently_selected_run,
      success: function(html){
        $("#plan_stages").html(html);
      }
    });
  }
}
