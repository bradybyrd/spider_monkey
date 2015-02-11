////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

/**
 * @author piyushpatil
 */

$(document).ready(function(){
	
  $('body').on('click', ".view_type", function(){
    var display_format = $('select#display_format option:selected').val();
    var action;

    if($(this).val() != undefined && $(this).val().indexOf("upcoming-requests") != -1) {
      action = $(this).val().replace("&display_format="+display_format,"");
    } else {
      action = $(this).val();
    }
    var form = $(this).parents('form:first');
    form.attr('action', action);
    form.submit();
  });
	
});


function calendarReport(format) {
	var filterForm = $("#filter_form");
        if(format == "html"){
            formatField = '<input type="hidden" name="format" id="format_type" value="pdf" />';
        }else{
            formatField = '<input type="hidden" name="format" id="format_type" value="' + format + '" />';
        }
	filterForm.append(formatField);
        if(format == "html"){
            filterForm.append('<input type="hidden" name="export" id="export" value="true" />');
        }
	mergeFilters(filterForm);
  if(format == "csv") {
    filterForm.attr("action", url_prefix + "/calendars/upcoming-requests");
  }
	filterForm.submit();
	$("#format_type").remove();
	$(".filterField").remove();
}

