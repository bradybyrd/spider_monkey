////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function(){

	$('body').on('change', ".user_default_roles", function(){
		saveDefaultRole($(this));
	});

//  $('.UserSettings li').click(function() {
//    clickedLi = $(this);
//    clickedLi.parent().children().each(function(index){
//      if ($(this).attr('tab') == clickedLi.attr('tab')){
//        $(this).addClass('selected');
//        $("#" + $(this).attr('tab')).show();
//      } else {
//        $(this).removeClass('selected');
//        $("#" + $(this).attr('tab')).hide();
//      }
//    });
//    return false;
//  });
	$('select').on('change', function(target){
		if($(this).val()=='not_visible'){
			alert($('.button').data('confirmation'));
		}
	})

	$('body.users a.more-links').on('click', function() {
  	$(this.parentNode.parentNode.children).toggleClass('hidden')
	})
});

function setUserEnvRoles(env_roles) {
	$.each (env_roles, function (i, env_role) {
		$("#user_env_roles_" + env_role['environment_role']['environment_id'] + "_visible").attr('checked', env_role['environment_role']['visible']);
		$("#user_env_roles_" + env_role['environment_role']['environment_id'] + "_role").val(env_role['environment_role']['role'])
  });
  disableInvisibleEnv();
}

function selectAllapps() {
  $("#visible_apps :checkbox").each( function() {
    $(this).attr('checked', true);
		loadAppEnvTable($(this));
 });
}

function clearAllapps() {
  $("#visible_apps :checkbox").each( function() {
    $(this).attr('checked', false);
		loadAppEnvTable($(this));
 });
}


function toggleAppList(clickedLink) {
	var rel = clickedLink.attr('rel')
	var title = clickedLink.html();
	clickedLink.html(rel);
	clickedLink.attr('rel', $.trim(title));
	toggleElem('appList');
}

function loadAppEnvTable(selectedApp) {
	var divId = selectedApp.attr('id').replace(/user_app_/g, '');
	var appEnvTableDiv = "#app_env_table_" + divId
	if ($(appEnvTableDiv).length == 0){
		$("#app_env_tables").append("<div id='"+ "app_env_table_" + divId + "'></div>")
	}
	if (selectedApp.attr('checked') == 'checked' || selectedApp.attr('checked') == true ) {
		$.ajax({
		  url: $("#content_box").find("form:first").attr("action") + "/associate_app",
			data: {"app_id" :divId},
			type: "POST",
			success: function(partial) {
				$(appEnvTableDiv).html(partial);
				$(appEnvTableDiv).find("select").val($("#defaultRoles input:radio:checked").val());
			}
		});
	} else {
		$.ajax({
		  url: $("#content_box").find("form:first").attr("action") + "/disassociate_app",
			data: {"app_id" :divId},
			type: "DELETE",
			success: function(data) {
				$(appEnvTableDiv).html("");
			}
		});
	}
}

function setVisibleApps(app_ids){
	selectCheckboxes(app_ids, "#user_app_");
}

function saveDefaultRole(checkbox){
	var role = checkbox.val();
	$.ajax({
	  url: $("#content_box").find("form:first").attr("action") + "/update_roles",
		data: {"roles[]": role},
		type: "PUT",
		success: function() {
			checkbox.show().stopSpin();
		}
	});
}

function disableInvisibleEnv() {
	$("#env_roles :checkbox").each( function() {
    if ($(this).attr('checked') == false){
			$("." + $(this).attr('rel')).find('select').val('').attr('disabled', true);
		} else {
			$("." + $(this).attr('rel')).find('select').attr('disabled', false);
		}
  });
}
