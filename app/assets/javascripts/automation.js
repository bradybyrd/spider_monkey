////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(document).ready(function() {

	$('body').on('change', "#script_integration_id", function() {
		if ($(this).val() == ""){
			//alert("Please choose a integration server")
		} else {
			updateIntegrationItems();
		}

        });

	$('body').on('change', "#script_template_script", function() {
		if ($(this).val() == ""){
			alert("Please choose a script")
		} else {
			$("#script_integration_id").trigger("change");
			getContentOfSelectedScript();
		}
        });

	$('body').on('change', "#script_job", function() {
		if ($(this).val() == ""){
//			alert("Please choose a job")
		} else {
			buildJobParameters();
		}
  });

	$('body').on('change', "#import_integration_id", function() {
		if ($(this).val() == ""){
			//alert("Please choose a integration server")
		} else {
			updateImportItems();
		}
  });

	$("#script_automation_category").livequery('change', function() {
		display_apply_template_section($(this).val(), null, $("#script_automation_type").val());
		displayScriptForm($(this).val());
		clearScriptAttributes();		
		createTextAreaWithLines();
	});

	$("select#import_automation_type").livequery('change', function() {
		displayAutomationScripts($(this).val());
	});

	$("select#script_automation_type").livequery('change', function() {
		displayAutomationForm($(this).val(), null);
	});

	$("#automation_category_type").livequery('change', function() {
		displayImportedScripts($(this).val());
	});

	$(".script_body").linedtextarea(		
		{selectedLine: 1}
	);

	$('body').on('change', "#automation_integration_type", function() {
		if ($(this).val().length == 0){
			if ( $("input#project_server_id").length > 0 ){
				$("input#project_server_id").remove();
			}
		} else {
			updateIntegrationIdToImportScript($(this));
		}
  	});	

});

function updateIntegrationIdToImportScript(project_server){
	if ($("#import_library_section").html().length > 0){
		var project_server_id = project_server.val();
		var form = $("#import_library_section").find('form')
		form.find("input#project_server_id").remove();
		form.append('<input type="hidden" value="'+project_server_id+'" name="project_server_id" id="project_server_id"/>')
	}	
}

function getContentOfSelectedScript(){
  var template_script = $("#script_template_script").val().split("_")
	var script_type = template_script[0];
	var script_id = template_script[1];
	$.get(url_prefix + "/environment/scripts/" + script_id + "/find_script_template?script_type=" + script_type,
		function(script){
			$("#script_content").val(script);
		}, "text"
	);
}

function updateIntegrationItems(){
	var integration_id = $("#script_integration_id").val();
	// var script_class = $("#script_script_type").val();
	var script_class = $(".script_automation_type").html();
	switch(script_class){
		case "BladelogicScript":
			// nothin to do
			break;
		default:
			buildIntegrationParameters();
			break;
	}

}

function updateImportItems(){
	var integration_id = $("#import_integration_id").val();
	var url = url_prefix + "/environment/scripts/import_scripts_list?integration_id=" + integration_id
	$.get(url, function(script_List){
		$("#rest_script_list").html(script_List);
		}
	);
}

function getHudsonJobs(){
	var integration_id = $("#script_integration_id").val();
	$.get(url_prefix + "/environment/hudson_scripts/" + integration_id + "/find_jobs",
		function(jobs){
			$("#script_job").html(jobs);
			$("#script_job").trigger("change");
		}, 'text'
	);
}

function buildJobParameters(){
	var template_script = $("#script_template_script").val();
	var orig_script = $("#script_content").val();
	var cur_len = orig_script.length;
	if (cur_len < 4){
		alert("Cannot add job information to an empty script.");
		$("#script_job").val('');
	} else {
		var template_script = template_script.split("_");
		var script_type = template_script[0];
		var orig_script = $("#script_content").val();
		var cur_len = orig_script.length;
		var script_id = template_script[1];
		var integration_id = $("#script_integration_id").val();
		var url = url_prefix + "/environment/scripts/" + integration_id + "/build_job_parameters?"
		url += "job=" + $("#script_job").val()
		if (template_script.length > 1)
		{
			url +=  "&script_type=" + template_script[0] + "&script_id=" + template_script[1];
		}

		$.get(url, function(int_params){
			var ipos = orig_script.search("###");
			var script = '';
			if(ipos > -1){
				var ipos2 = orig_script.slice(ipos+3).search("###");
				if(ipos2 > -1){
					script = orig_script.slice(0,(ipos+3+ipos2+4)) + int_params + orig_script.slice((ipos+3+ipos2+4));
				}else{
					script = orig_script.slice(0,(ipos+3)) + int_params + orig_script.slice((ipos+3));
				}
			}else{
				script = "###\n" + int_params + orig_script;
			}
			$("#script_content").val(script);
		}, 'text');
	}
}

function buildIntegrationParameters(){
	var script_class = $("#script_class").val();
	var orig_script = $("#script_content").val();
	var cur_len = orig_script.length;
	if (cur_len < 4){
		alert("Cannot add integration server to an empty script.");
		$("#script_integration_id").val('');
	} else {
		var integration_id = $("#script_integration_id").val();
		var url = url_prefix + "/project_servers/" + integration_id + "/build_parameters"
        $.ajax({
            url : url,
            type : "POST",
            data : {"script_content" : orig_script },
            dataType: "text",
            success: function(data) {
                $("#script_content").val(data);
			}
	    });
	}
}

function Old_buildJobParameters(){
	var template_script = $("#script_template_script").val();
	if (template_script == ""){
		alert("Please choose a template script");
	} else {
		var template_script = template_script.split("_");
		var script_type = template_script[0];
		var script_id = template_script[1];
		var integration_id = $("#script_integration_id").val();
		var url = url_prefix + "/environment/scripts/" + integration_id + "/build_job_parameters?"
		url += "job=" + $("#script_job").val()
		url +=  "&script_type=" + template_script[0] + "&script_id=" + template_script[1];
		$.get(url, function(script){
			$("#script_content").val(script);
		});
	}
}

function display_apply_template_section(script_type, script_object, automation_type){
	if (script_object != null) {
		script_hash = {}	
		$.each(script_object, function(attribute, value) {
			if (attribute == "template_script_id" || attribute == "template_script_type" || attribute == "integration_id"){
				script_hash[attribute] = value
			}			
		});
	}	
	if (script_type != '') {
		var url = url_prefix + "/environment/scripts/render_integration_header"
		$.get(url, {'script_type': script_type, 'script_hash': script_hash, 'automation_type': automation_type }, function(data){
			$(".apply_template_section").html(data.split("&nbsp;")[0]);
			$(".integration_server_section").html(data.split("&nbsp;")[1]);
		}, 'text');		
	}
}

function displayScriptForm(script_type){
	if (script_type.length > 0){
		$(".script_form").show();
		$(".ssh_content").show();
		$(".script_automation_type").html(script_type);		
	} else {
		$(".script_form").hide();
	}
}

function displayAutomationScripts(value){
	if (value.length > 0){
		url = url_prefix + "/environment/scripts/render_automation_types"
		$.get(url, {'automation_type': value}, function(data){
			$("#automation_category_type").html(data);
		}, "text");		
	} else {
		$("#automation_category_type").html("<option value='Select'>Select</option>");
		if ($("#import_library_section").length > 0){
			$("#import_library_section").hide();
		}
	}

}

function displayAutomationForm(automation_type, script_object){
	if (script_object != null) {
		script_hash = {}	
		$.each(script_object, function(attribute, value) {
			script_hash[attribute] = value				
		});
	}	
	if (automation_type.length > 0) {
		url = url_prefix + "/environment/scripts/render_automation_form"
		$.post(url, {'automation_type': automation_type, 'script_hash': script_hash}, function(data){
			$("#automation_form").show();
			$("#automation_form").html(data);
		}, "text");		
	} else {
		$("#automation_form").hide();
	}
}


function displayImportedScripts(automation_type){
	if (automation_type.length > 0 && automation_type != "Select") {
		var folder = $("#import_automation_type").val();		
		var integration_server = $("#automation_integration_type").val();
		url = url_prefix + "/environment/scripts/import_local_scripts_list"
		$.get(url, {'sub_folder': automation_type, 'folder': folder, 'integration_server': integration_server}, function(data){
			$("#import_library_section").show();
			$("#import_library_section").html(data);
		}, "text").error(function() { $("#import_library_section").hide(); });		
	} else {
		$("#import_library_section").hide();
	}
}

function clearScriptAttributes(){
	$("#script_name").val('');
	$("#script_description").val('');
	$("#script_content").val('');	
	$("#script_unique_identifier").val('');	
}

function createTextAreaWithLines(script_id){	
	if (script_id != undefined){
		$("tr#script_"+script_id+"_row").find("#script_content").linedtextarea(		
			{selectedLine: 1}
		);	
	} else {
		if ($(".linedtextarea").length == 0){
			$(".script_body").linedtextarea(		
				{selectedLine: 1}
			);	
		}
	}
}

function scriptUpdateToFile(caller){
	form = $("#basic_form");
	curPath = form.find('#script_file_path').val();
	content = form.find("#script_content").val();
	action = form.attr("action").replace('update_script','update_to_file');
	if (curPath.length > 10) {
		url = url_prefix + action;
		$.post(url, {'file_path': curPath, 'content': content});		
	} else {
		alert("Enter a file path for saving");
	}
}

function scriptUpdateFromFile(caller){
	form = $("#basic_form");
	curPath = form.find('#script_file_path').val();
	content = form.find("#script_content").val();
	action = form.attr("action").replace('update_script','update_from_file?file_path=' + curPath);
	if (curPath.length > 10) {
		url = url_prefix + action;
		$.get(url, function(newContent) {
			form.find("#script_content").val(newContent);
			//$("#script_content").val(script);
		}, "text");		
	} else {
		alert("Enter a file path for saving");
	}
}