////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
	
	$('body').on('change', "#run_start_at_date", function() {
		if($(this).val() != ""){
			$('#request_planned_at_to_run_start_at').attr("disabled", false);
		}else{
			$('#request_planned_at_to_run_start_at').attr('checked', false)
			$('.request_planned_date').attr("disabled", false);
			$('#request_planned_at_to_run_start_at').attr("disabled", true);
		}
  });

	$('body').on('change', '#request_planned_at_to_run_start_at', function() {
		if($('.request_planned_date').attr("disabled")){
			$('.request_planned_date').attr("disabled", false);
		}else{
			$('.request_planned_date').attr("disabled", true);			
		}
	});

	$('body').on('change', "#run_start_at_to_planned_at_earliest_request", function() {
		if($("#run_start_at_date").attr("disabled")){
			$(".start_at").attr("disabled", false);
			if ($("#run_start_at_date").val() != ""){
				$("#request_planned_at_to_run_start_at").attr("disabled", false);
			}
		}else{
			$(".start_at").attr("disabled", true)
			$("#request_planned_at_to_run_start_at").attr("checked", false);
			$("#request_planned_at_to_run_start_at").attr("disabled", true);
		}	
	});
	
	$('body').on('change', ':input[id^=request_scheduled_at_]', function(){
		if ($('p#rescheduled_field').hasClass('old_record')) {
			$('p#rescheduled_field').show();
			if ($('#request_rescheduled').attr('checked') != 'false') {
				$('#request_rescheduled').attr('checked', true);
			}
		}
	});
	
	// custom select all to all selecting stage by stage
	$('body').on('click', "input.check_all_input", function() {
		toggleCheckBox($(this).attr("check_box_dom"), $(this).is(':checked'));
  	});
  	
  	// listens for request checks and unchecks select all if clicked individually
  	$('body').on('click', "input.requests_", function() {
  		var stage_id = $(this).attr('data-stage-id')
  		var select_all_dom_id = "#select_all_check_stage_" + stage_id
  		var closest_select_all = $(select_all_dom_id)
		closest_select_all.removeAttr("checked"); 
  	});

	//$('form.plan_stage_run_create').onsubmit = contractSetupSubmit;

	$('body').on('click', 'ul.planTabs li a', function(event) {
		event.preventDefault();
		if($('ul.planTabs li.selected a').attr('href') == $(this).attr('href')) {
			// If we are already on the tab that is being clicked, return
			return false;
		}
		$('ul.planTabs li').removeClass('selected');
		$(this).parents('li:first').addClass("selected");
		$(".content.horizontal_scroll").load($(this).attr('href'), function() {
			$(".vscroll_960").css('width', screen.width - 430 + "px");
		});
                sortable_table_header_arrow_assignment();
	});

	$("#calendar_period").change(function() {
		loadReleases();
	});
	$("#app_id").change(function() {
		loadReleases();
	});

	$('body').on('click', 'a.new_activity', function() {
		$('#new_plan_activity').show().find(':input').removeAttr('disabled');
		$('#existing_plan_activity').hide().find(':input').attr('disabled', 'disabled');
		return false;
	});

	$('body').on('click', 'a.cancel', function() {
		$('#new_plan_activity').hide().find(':input').attr('disabled', 'disabled');
		$('#existing_plan_activity').show().find(':input').removeAttr('disabled');
		return false;
	}).click();

	$('body').on('submit', '#plan_prepare_activity form', function() {
		var form = $(this);
		var stageId = $(this).find('[name="plan_stage_id"]').val();
		var selectedMembers = $('input.plan_stage_' + stageId + '[name="member_ids[]"]:checked');

		selectedMembers.each(function() {
			form.append($('<input name="member_ids[]" type="hidden" value="' + $(this).val() + '" />'));
		});
	});

	$('body').on('click', '.requestList th.sortable', function() {
		
		var form = $(this).closest("form");
		var plan_id = form.attr('data-plan-id');
		var plan_stage_id = form.attr('data-plan-stage-id');
		var filters_sort_scope = form.attr('data-filters-sort-scope');
		var filters_sort_direction = form.attr('data-filters-sort-direction');
		if(filters_sort_scope != $(this).attr('data-column')) {
			filters_sort_scope = $(this).attr('data-column');
			filters_sort_direction = 'asc';
		} else {
			filters_sort_direction = (filters_sort_direction == 'asc') ? 'desc' : 'asc' ;
		}

		$.ajax({
			type : "GET",
			data : $('#filter_form').serialize(),
			url : url_prefix + '/plans/' + plan_id + '?filters[sort_scope]=' + filters_sort_scope + '&filters[sort_direction]=' + filters_sort_direction,
			success : function(data) {
				$("#plan_stages").html(data);
                                sortable_table_header_arrow_assignment();
			}
		});
	});
});
function loadReleases() {
	$("#releases").css("border", "none");
	$.get(url_prefix + '/plans/release_calendar', {
		'period' : $("#calendar_period").val(),
		'app_id' : $("#app_id").val()
	}, function(releases_partial) {
		$("#releases").css("border", "1px solid #CCCCCC")
		$("#releases").html(releases_partial);
	});
}

function setStageDates(stages) {
	$.each(stages, function(idx, stage_id) {
		var stage_date_html = $("#stage_date_" + stage_id).html();
		dates = $("#stage_date_" + stage_id).html().match(/\b\d{1,2}[\/-]\d{1,2}[\/-]\d{4}\b/g)
		if(dates != null) {
			$("#stage_" + stage_id + "_start").html(dates[0]);
			$("#stage_" + stage_id + "_end").html(dates[1]);
		}
	});
}

// this function is called by the create run button and passed the plan and
// stage for which it is to be created, but only if requests are selected.
function submitCreateRunForm(plan_id, plan_stage_id) {
	var request_ids = [];
	var request_stage_ids = [];
	var arr = new Array();
	$("input[name='requests[]']:checked").each(function() {
		request_ids.push($(this).attr("value"))
	});
	$("input[name='requests[]']:checked").each(function() {
		request_stage_ids.push($(this).attr("data-stage-id"))
	});
	arr = uniqArray(request_stage_ids);
	if(request_ids.length > 0) {
		$.facebox(function() {
			$.get(url_prefix + "/plans/" + plan_id + "/runs/new", {
				'request_ids[]' : request_ids,
				'request_stage_ids[]' : arr,
				'plan_stage_id' : plan_stage_id
			}, function(data) {
				$.facebox(data);
			});
		});
	} else {
		alert("Please select Requests before creating a new Run. Use checkboxes placed on extreme right.")
	}
	return false;
}

// this function is called when a run is complete and has a required
// next stage to which we can promote all the requests.
function submitPromoteRunForm(plan_id, plan_stage_id, run_to_clone_id, next_required_stage_id) {
    $.facebox(function() {
        $.get(url_prefix + "/plans/" + plan_id + "/runs/new", {
            'run_to_clone_id' : run_to_clone_id,
            'next_required_stage_id' : next_required_stage_id,
            'plan_stage_id' : plan_stage_id
        }, function(data) {
            $.facebox(data);
        });
    });
    return false;
}

// this function is called by the add to run button and passed the
// set of request id tags currently selected.
function submitAmmendRunForm(plan_id, plan_stage_id, run_id) {
	var request_ids = [];
	var request_stage_ids = [];
	var arr = new Array();
	$("input[name='requests[]']:checked").each(function() {
		request_ids.push($(this).attr("value"))
	});
	$("input[name='requests[]']:checked").each(function() {
		request_stage_ids.push($(this).attr("data-stage-id"))
	});
	arr = uniqArray(request_stage_ids);
	if(request_ids.length > 0) {
		$.facebox(function() {
			$.post(url_prefix + "/plans/" + plan_id + "/runs/select_run_for_ammendment", {
				'request_ids[]' : request_ids,
				'request_stage_ids[]' : arr,
				'plan_stage_id' : plan_stage_id,
				'run_id' : run_id
			}, function(data) {
				$.facebox(data);
			});
		});
	} else {
		alert("Please first select Requests to add to an existing Run. Use checkboxes placed on extreme right.")
	}
	return false;
}

// this function drops runs from their request
// this function is called by the drop from run button and passed the
// set of request id tags currently selected.
function submitDropRunForm(plan_id, plan_stage_id, run_id) {
	var request_ids = [];
	var request_stage_ids = [];
	var arr = new Array();
	$("td input[name='requests[]']:checked").each(function() {
		request_ids.push($(this).attr("value"))
	});
	$("td input[name='requests[]']:checked").each(function() {
		request_stage_ids.push($(this).attr("data-stage-id"))
	});
	arr = uniqArray(request_stage_ids);
	if(request_ids.length > 0) {
		$.postGo(url_prefix + "/plans/" + plan_id + "/runs/drop", {
			'request_ids[]' : request_ids,
			'request_stage_ids[]' : arr,
			'plan_stage_id' : plan_stage_id,
			'run_id' : run_id
		});
	} else {
		alert("Please first select Requests to remove from any assigned runs. Use checkboxes placed on extreme right.")
	}
	return false;
}

function moveRequests(plan_id) {
	var request_ids = [];
	var request_ids_checked = [];
	var arr = new Array();
	$("input[name='requests[]']:checked").each(function() {
		request_ids.push($(this).attr("value"))
	});
	$("input[name='requests[]']:checked").each(function() {
		request_ids_checked.push($(this).attr("data-stage-id"))
	});
	arr = uniqArray(request_ids_checked);
	if(request_ids.length > 0) {
		$.facebox(function() {
			$.get(url_prefix + "/plans/" + plan_id + "/move_requests", {
				'request_ids[]' : request_ids
			}, function(data) {
				$.facebox(data);
				if(arr.length == 1) {
					$('#stage_id_' + arr[0]).attr('disabled', 'disabled');
				}
			});
		});
	} else {
		alert("Please select Requests to move between stages. Use checkboxes placed on extreme right.")
	}
}

function highLightCurrentDay(day) {
	$('td[day*="' + day + '"]').css("background-color", "#FFFF00");
}

// a convenience function for non-ajax gets and posts
// see http://stackoverflow.com/questions/1149454/non-ajax-get-post-using-jquery-plugin#_=_
(function($) {
	$.extend({
		getGo : function(url, params) {
			document.location = url + '?' + $.param(params);
		},
		postGo : function(url, params) {
			var $form = $("<form>").attr("method", "post").attr("action", url);
			$.each(params, function(name, value) {
				if( value instanceof Array) {
					$.each(value, function(index, subvalue) {
						$("<input type='hidden'>").attr("name", name).attr("value", subvalue).appendTo($form);
					});
				} else {
					$("<input type='hidden'>").attr("name", name).attr("value", value).appendTo($form);
				}

			});
			$form.appendTo("body");
			$form.submit();
		}
	});
})(jQuery);
