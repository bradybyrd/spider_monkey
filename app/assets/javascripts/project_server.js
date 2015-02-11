////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

function checkWorkspaceDataAvailability(){
	var form = $(".cssform")
	$.ajax({
	  url: form.attr("action") + "/workspace_data_available.json",
	  dataType: 'json',
	  success: function(integration_info){
			submit_button = form.find("input[type='submit']");
			if (integration_info.fetch_workspace_data){
				submit_button.removeAttr("disabled");
				form.find("#fetch_data_link").removeClass("dn");
				form.find("#data_status").html("");
				form.find("#data_status").addClass("dn");
				form.find("#stop_data_fetching").addClass("dn");
			} else {
				submit_button.attr("disabled", "disabled");
				form.find("#data_status").html("Status: " + integration_info.status);
				form.find("#data_status").addClass("dn");
				form.find("#data_status").removeClass("dn");
				form.find("#stop_data_fetching").removeClass("dn");
			}
		}
	});
}

function ORIGcheckWorkspaceDataAvailability(){
	var form = $(".cssform")
	$.ajax({
	  url: form.attr("action") + "/workspace_data_available.json",
	  dataType: 'json',
	  success: function(allow_to_fetch_workspace_data){
			submit_button = form.find("input[type='submit']");
			message_span = submit_button.next();
			if (allow_to_fetch_workspace_data){
				submit_button.removeAttr("disabled");
				message_span.addClass("dn");
				form.find("#fetch_data_link").removeClass("dn");
				form.find("span:last").addClass("dn");
			} else {
				submit_button.attr("disabled", "disabled");
				message_span.removeClass("dn");
				form.find("#fetch_data_link").addClass("dn");
				form.find("span:last").removeClass("dn");
			}
		}
	});
}
