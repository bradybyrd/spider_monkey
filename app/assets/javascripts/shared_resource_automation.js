////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function(){

	$('body').on('blur',"input.step_script_argument[parent_argument='true']", function(event){
		if (typeof adapter_name_values == "undefined") {
			adapter_name_values = []
		}
		if ($(this).val().length > 0 && $(this).attr("target_arguments_to_load") != undefined && $(this).attr("target_arguments_to_load") != "null"){
			target_ids_to_load = $(this).attr("target_arguments_to_load").split(",")
			if ($.inArray($(this).val(), adapter_name_values) == -1){
				$(this).prop("disabled", true);
				adapter_name_values = [];
				adapter_name_values.push($(this).val());
				executeResourceAutomation($(this), target_ids_to_load);
			}
		}
		if ($(this).val().length > 0 && $(this).attr("target_arguments_to_load") == undefined && $(this).attr("target_argument_to_load") != undefined && $(this).attr("target_arguments_to_load") != "null") {
			if ($.inArray($(this).val(), adapter_name_values) == -1){
				adapter_name_values = []
				adapter_name_values.push($(this).val())
				executeResourceAutomation($(this), null);
			}
		}
	});

	$('input.argument_in_time').livequery(function() {
		$(this).timepicker({});
	});

	$('input.argument_in_datetime').livequery(function() {
		$(this).datetimepicker({
			dateFormat: $('#datepicker_format').val()
		});
	});

	$('body').on('click','a.add_argument_fields', function(event){
		time = new Date().getTime()
		regexp = new RegExp($(this).data('id'), 'g')
		$(this).before($(this).data('fields').replace(regexp, time))
		$(this).hide();
		event.preventDefault();
		});

	$('body').on('click','a.remove_argument_fields', function(event){
		parent_div = $(this).parents('td:first')
		parent_div.find('a.add_argument_fields').show();
		$(this).prev('input[type=hidden]').val('1')
		$(this).closest('fieldset').hide()
		event.preventDefault()
	});

	// this was left behind in steps.js and was no longer working for external tickets as a result
	$('body').on('click', 'table input[id^="selectArgumentItem"]', function(event) {
		var table_argument_id = $(this).attr("id").split('_')[1];
		var selected_ids = [];
		if ($('#arg_in_data_list_for_table_' + table_argument_id).children('input').length > 0) {
			$('#arg_in_data_list_for_table_' + table_argument_id).children('input').each(function() {
				selected_ids.push($(this).val());
			});
		}
		var selected_id = $(this).val();
		if ($.inArray(selected_id, selected_ids) == -1 && $(this).is(':checked')) {
			$('<input type="hidden" value="' + selected_id + '" name="argument[' + table_argument_id + '][]" id="argument_' + table_argument_id + '_' + selected_id + '">').appendTo('#arg_in_data_list_for_table_' + table_argument_id);
		} else if (!$(this).is(':checked')) {
			var $table = $('#table_arg_' + table_argument_id);
			if ($table.attr('argument_value')) {
				var selected_values = JSON.parse($table.attr('argument_value'));
				selected_values = $.grep(selected_values, function(value) { return value != selected_id; });
				$table.attr('argument_value', JSON.stringify(selected_values));
			}
			$('#argument_' + table_argument_id + '_' + selected_id).remove();
		}

	});


});

// This function is used for execution of resource automation which are dependent on some fields

function executeResourceAutomation(obj, target_args_to_load){
	var step_obj = $('#argument_grid').data('step_obj');
	argument_ids = []
	target_hash = {}
	selected_argument_values = {}
	selected_argument_id = obj.attr("id").split("_")[2] //script_argument_10100

	$(".step_script_argument").each(function(index) {
		if ($(this).attr("depends_on") != undefined){
			dependent_argument = $(this)
			$.merge(argument_ids, $(this).attr("depends_on").split(","));
		}
	});
	conds1 = $.inArray(selected_argument_id, argument_ids) != -1
	conds2 = obj.attr("target_arguments_to_load") != undefined
	conds3 = obj.attr("target_argument_to_load") != undefined

	if ( conds1 || conds2 || conds3 ){

		if (target_args_to_load == null && obj.attr("target_arguments_to_load") != undefined){
			target_args_to_load = obj.attr("target_arguments_to_load").split(",");
		}

		if (target_args_to_load == null){
			target_argument_id = obj.attr("target_argument_to_load");
		} else {
			target_argument_id = target_args_to_load[0]
			var removeItem = target_argument_id;
			target_args_to_load = $.grep(target_args_to_load, function(value) {
									return value != removeItem;
								 });
			}
		url = url_prefix + "/environment/scripts/execute_resource_automation"

		if (obj.attr("type") == "text"){
			if (obj.attr("target_argument_to_load") != undefined){
				if ($("select#script_argument_"+target_argument_id).attr("depends_on") != undefined ){
					populateArgumentValues('select#script_argument_', target_argument_id, selected_argument_values);
				}
				if ($("input#script_argument_"+target_argument_id).attr("depends_on") != undefined ){
					populateArgumentValues('input#script_argument_', target_argument_id, selected_argument_values);
				}
				if ($('#table_arg_' + target_argument_id).parent().attr('depends_on') != undefined) {
					populateArgumentValues('#table_arg_', target_argument_id, selected_argument_values, true);
				}
			}
		} else {
			if ($("select#script_argument_"+target_argument_id).attr("depends_on") != undefined ){
				populateArgumentValues('select#script_argument_', target_argument_id, selected_argument_values);
			} else if ($("input#script_argument_"+target_argument_id).attr("depends_on") != undefined ){
				populateArgumentValues('input#script_argument_', target_argument_id, selected_argument_values);
			}
			else {
				selected_argument_values[obj.attr("id").split("_")[2]] = obj.val()
			}
		}

        arg_value = $("select#script_argument_"+target_argument_id).attr("arg_val");

			$.ajax({
					type: "POST",
					async: false,
					data: {'target_argument_id': target_argument_id, 'source_argument_value': selected_argument_values,
										'step_obj': step_obj, 'value': arg_value},
					url: url,
					beforeSend: function() {
						$("select#script_argument_"+target_argument_id).hide();
						$("td#argument_"+target_argument_id).addClass("resource_automation_loader");
					},
					success: function(data) {
						if ($("select#script_argument_"+target_argument_id).length > 0){
							$("td#argument_"+target_argument_id).removeClass("resource_automation_loader");
							$("select#script_argument_"+target_argument_id).show();
							$("select#script_argument_"+target_argument_id).html(data);
						} else if ($("input#script_argument_"+target_argument_id).length > 0){
							$("td#argument_"+target_argument_id).removeClass("resource_automation_loader");
							$("input#script_argument_"+target_argument_id).show();
							$("td#argument_"+target_argument_id).html(data);
						} else {
							$("td#argument_"+target_argument_id).removeClass("resource_automation_loader");
							$("td#argument_"+target_argument_id).html(data);
						}

					},
					complete: function(jqXHR, textStatus){
						if (target_args_to_load != null && target_args_to_load.length == 0){
							obj.removeAttr("disabled");
						}
						if ((step_obj != null) && (step_obj["id"] != null)) {
							if (target_args_to_load != null){
								if (target_args_to_load.length == 0){
									if ( (typeof trigger_resource_automation_for_ids != 'undefined') && $.inArray(target_argument_id, trigger_resource_automation_for_ids) != -1 ){
										trigger_resource_ids = find_valid_resource_automation_ids(trigger_resource_automation_for_ids)
								target_id = trigger_resource_ids[0]
								var removeItem = target_id;
								trigger_resource_ids = $.grep(trigger_resource_ids, function(value) {
														return value != removeItem;
													 });

								$("select#script_argument_"+target_id).trigger("change");
									} else {
										$("select#script_argument_"+target_argument_id).trigger("change");
									}
								}
							}
							if (target_args_to_load == null){
								if ( (typeof trigger_resource_automation_for_ids != 'undefined') && $.inArray(target_argument_id, trigger_resource_automation_for_ids) != -1 ){
									trigger_resource_ids = find_valid_resource_automation_ids(trigger_resource_automation_for_ids)
									target_id = trigger_resource_ids[0]
									var removeItem = target_id;
									trigger_resource_ids = $.grep(trigger_resource_ids, function(value) {
										return value != removeItem;
									 });
									if ($("select#script_argument_"+target_id).attr("target_argument_to_load") != undefined) {
										$("select#script_argument_"+target_id).trigger("change");
									}

								} else {
									$("select#script_argument_"+target_argument_id).trigger("change");
								}
							} else if (target_args_to_load.length > 0) {
								triggerDependentResourceAutomations(target_argument_id, target_args_to_load, step_obj["id"])
							}
						}
						if (target_args_to_load != null && target_args_to_load.length > 0){
							executeResourceAutomation(obj, target_args_to_load);
						}

						if (obj.attr('trigger_function') != undefined ){
							triggerAdapterResourceAutomation();
						}
					},
					error: function(jqXHR, textStatus, errorThrown){
					}
			});

	}
}

function populateArgumentValues(selector, id, hash, is_table){
	is_table = typeof is_table !== 'undefined' ? is_table : false;
	$selector = is_table ? $(selector + id).parent() : $(selector + id);

	$.each($selector.attr('depends_on').split(","), function(index, value) {
		if ($("input#script_argument_" + value).val() == undefined){
			hash[value] = $("select#script_argument_"+value).val();
		} else {
			hash[value] = $("input#script_argument_"+value).val();
		}
	});
}

function find_valid_resource_automation_ids(arg_ids){
	valid_arrg_ids = []
	$.each(arg_ids, function(index,value){
		if($("select#script_argument_"+value).attr("target_argument_to_load") != undefined){
			valid_arrg_ids.push(value);
		}
	});
	return valid_arrg_ids
}

function triggerDependentResourceAutomations(target_argument_id, target_args_to_load, step_obj_id){
	if (typeof dependent_resource_automations == 'undefined' ){
		dependent_resource_automations = []
	} else {
		dependent_resource_automations.push(target_argument_id);
	}
	if (step_obj_id != null && target_args_to_load == 0) {
		$("select#script_argument_"+dependent_resource_automations[0]).trigger("change");
	}
}

function triggerResourceAutomation(){
	parent_arg = $("select.step_script_argument")
	if (parent_arg.attr("target_argument_to_load") != undefined && parent_arg.val() != null && parent_arg.val().length > 0){
		dependent_resource_automations = []
		$("select.step_script_argument").attr("trigger_function", true);
		$("select.step_script_argument").trigger("change");
	} else {
		triggerAdapterResourceAutomation();
	}

	parent_arg_with_input_field = $("input.step_script_argument[parent_argument='true']");
	if (typeof parent_arg_with_input_field != 'undefined' && typeof parent_arg_with_input_field.val() != 'undefined'){
		target_arguments_to_load_blank = parent_arg_with_input_field.attr("target_arguments_to_load") == undefined || parent_arg_with_input_field.attr("target_arguments_to_load") == 'null';
		if (parent_arg_with_input_field.val().length > 0 && target_arguments_to_load_blank && parent_arg_with_input_field.attr("target_argument_to_load") != undefined) {
			executeResourceAutomation(parent_arg_with_input_field, null);
		}
	}
}

function triggerAdapterResourceAutomation(){
	if ($("input.step_script_argument[parent_argument='true']").val() != undefined && $("input.step_script_argument[parent_argument='true']").val().length > 0 ){
		obj = $("input.step_script_argument[parent_argument='true']")
		if (obj.attr("target_arguments_to_load") != undefined){
			obj.prop("disabled", true);
			trigger_resource_automation_for_ids = obj.attr("target_arguments_to_load").split(",")
			executeResourceAutomation(obj, trigger_resource_automation_for_ids);
		}
	}
}

function updateTargetArgumentId(){
	$("select.step_script_argument, input.step_script_argument").each(function(index) {
		target_arg_id = findTargetArgumentId($(this));
		if (target_arg_id != "null") {
			$(this).attr("target_argument_to_load", target_arg_id)
		}
	});

	$("input.step_script_argument, select.step_script_argument").each(function(index){
		target_arg_ids = findMultipleTargetArgumentIds($(this));
		if (target_arg_ids.length > 0){
			$(this).attr("target_arguments_to_load", target_arg_ids)
		}
	});
}

function findMultipleTargetArgumentIds(argument){
	arg_hash = {}

	argument_id = argument.attr("id").split("_")[2]

	$("select.step_script_argument, input.step_script_argument").each(function(index) {
		arg_arr = []
		if($(this).attr("depends_on") != undefined && $(this).attr("id") != argument.attr("id") ){
			$.each($(this).attr("depends_on").split(","), function(index, value) {
				arg_arr.push(value);
			});
			if ($.inArray(argument_id, arg_arr) != -1){
				arg_hash[$(this).attr("id").split("_")[2]] = $(this).attr("depends_on").split(",").length
			}
		}
	});

	//find hash keys and values and store them in a array
	keys = []
	values = []
	argument_ids = []
	for (var k in arg_hash){
		if (arg_hash.hasOwnProperty(k)) {
			keys.push(k);
			values.push(arg_hash[k]);
			if (arg_hash[k] == "1"){
				argument_ids.push(k)
			} else if (arg_hash[k] > 1){
				$.each($("#script_argument_"+k).attr("depends_on").split(","), function(index, value) {
					if (value == argument_id){
						argument_ids.push(k);
					}
				});
			}
		}
	}

	if (argument_ids.length > 0){
		return argument_ids;
	} else {
		return "null";
	}

}

function findTargetArgumentId(argument){
	arg_hash = {}

	argument_id = argument.attr("id").split("_")[2]
	$("select.step_script_argument, input.step_script_argument").each(function(index) {
		arg_arr = []
		if($(this).attr("depends_on") != undefined && $(this).attr("id") != argument.attr("id") ){
			$.each($(this).attr("depends_on").split(","), function(index, value) {
				arg_arr.push(value);
			});
			if ($.inArray(argument_id, arg_arr) != -1){
				arg_hash[$(this).attr("id").split("_")[2]] = $(this).attr("depends_on").split(",").length
			}
		}
	});

	//find hash keys and values and store them in a array
	keys = []
	values = []
	for (var k in arg_hash){
		if (arg_hash.hasOwnProperty(k)) {
			keys.push(k);
			values.push(arg_hash[k]);
		}
	}

	if (values.length > 0){
		sorted_values = values.sort();
		first_val = sorted_values[0]

		argument_id = getHashKey(arg_hash, first_val);

		return argument_id;

	} else {
		return "null";
	}


}

function getHashKey(h, val){
	for (var k in h){
		if (h.hasOwnProperty(k)) {
			if(h[k] === val){
				return k;
			}
		}
	}
}