////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
FilterIds = ['aasm_state','plan_template_id', 'plan_type', 'app_id', 'stage_id', 'environment_id', 'release_manager_id', 'team_id', "release_id"];

$(document).ready(function() {
	open_close_filters();

	$('body').on('click', '#show_deleted, #hide_deleted, #hide_request_steps', function(event) {
		event.preventDefault();
		elementToggler(this, event);
	});

	$('body').on('change', '.request_filters', function() {
		var form = $(this).parents('form:first');
		var td = $(this).parents('td:first');
		var selectListId = td.find('select').attr('id');
		var currentValue = $('#' + selectListId + ' :selected').val();
		var currentValueText = $('#' + selectListId + ' :selected').text();
		var divEl = td.find('div');
		var selectedValues = divEl.text();
		matched = new RegExp(currentValueText, "i").test(selectedValues);
		if(currentValue == '' || matched == false) {
			hiddenField = '<input type="hidden" name="temp_filter" value="1" />';
			form.append(hiddenField);
			mergeFilters(form);
			form.submit();
			form.find('select').attr('disabled', 'disabled');
			form.find('input').attr('disabled', 'disabled');
			$("#facebox_overlay").show();
		}
	});

	$('.checkbox_request_filters').bind("change click keypress", function() {
		if(currentValue == '' || matched == false) {
			hiddenField = '<input type="hidden" name="temp_filter" value="1" />';
			form.append(hiddenField);
			mergeFilters(form);
			form.submit();
			form.find('select').attr('disabled', 'disabled');
			form.find('input').attr('disabled', 'disabled');
			$("#facebox_overlay").show();
		}
	});

	$('body').on('change', '.resource_filters', function() {
		var form = $(this).parents('form:first');
		$.ajax({
			type : "GET",
			data : form.serialize(),
			url : form.attr('action'),
			success : function(data) {
				$(".left .col .content:last").html(data);
				form.find('select').removeAttr('disabled');
				form.find('input').removeAttr('disabled');
			}
		});
	});

	$('body').on('click', 'a.clear_request_filters', function() {
		var form = $("#filter_form");
    authencity_token = $('input[name=authenticity_token]');
		$('#filter_form').find('select').attr('disabled', 'disabled');
		form.find('select').val('');
		form.find('div').html('');
		hiddenField = '<input type="hidden" name="clear_filter" value="1" />';
    form.append(authencity_token);
		form.append(hiddenField);
		form.submit();
		//disableForm(form);
		return false;
	});

	$('body').on('click', 'a#close_request_filters', function() {
		/* Open - 1, Closed - 0*/
		var f_state = $('#filter_block_collapse_state_flag').val();
		if(f_state == '1') {
			$('#filter_block_collapse_state_flag').val('0');
		} else {
			$('#filter_block_collapse_state_flag').val('1');
		}
		var form = $("#filter_form");
		disableForm(form);
		return false;
	});

	$('.checkbox_request_filters').bind("change click keypress", function() {
		var form = $(this).parents('form:first');
		form.submit();
		form.find('select').attr('disabled', 'disabled');
		form.find('input').attr('disabled', 'disabled');
	});

	$('body').on('click', 'div.selected_values a', showMultiSelect);
	$('body').on('click', 'div.values_to_select a.hide', updateSelectedValues);
	$('body').on('change', 'div.values_to_select select', toggleBlankSubmission);
        $('body').on('click', 'div.values_to_select a.clear',unselectSelectedFilterValues);
    $('div.values_to_select select').livequery(function() { $(this).change() });

    $('body').on('click', 'div.values_to_select a.cancel', updateSelectedValues);
	$('body').on('change', 'div.values_to_select select', function() {
		showLinks($(this));
	});
	$('bdoy').on('click', 'a.cancel_select', cancel_select);

	$('body').on('click', '#plan_results th.sortable', function() {
		if($('#filters_sort_scope').val() != $(this).attr('data-column')) {
			$('#filters_sort_direction').val('asc');
		} else {
			$('#filters_sort_direction').toggleValues('asc', 'desc');
		}

		$('#filters_sort_scope').val($(this).attr('data-column'));

		$.ajax({
			type : "POST",
			data : $('#filter_form').serialize(),
			url : $('#filter_form').attr('action'),
			success : function(data) {
				$("#plan_results").html(data);
				open_close_filters();
                                sortable_table_header_arrow_assignment();
			}
		});
	});
});
function setFilters(filters) {
	$.each(FilterIds, function(index, value) {
		if(filters != undefined) {
			$("#filters_" + value + "_").val(filters[value]);
			var values = $("#filters_" + value + "_").find('option:selected').map(function() {
				return $(this).html()
			}).join(', ');                       
			if(values != '') {
				var valtag = '<span class="multivalues">' + values + '&nbsp;</span>'
				$("#selected_values_" + value).find('.selected').prepend(valtag).find('a').html('edit');
			} else {
				$("#selected_values_" + value).find('.selected').prepend('&lt;no filter&gt;&nbsp;');
			}
		}
	});
}

function showMultiSelect() {
	var attr_id = $(this).attr('data-attr-id');
	$('#values_to_select_' + attr_id).show();
	$(this).parents('div').next('div').find('select').show();
	$(this).parents('div').next('div').find('a.cancel_select').show();
	$(this).parent().hide();
	return false;
}

function toggleBlankSubmission() {
	if($(this).val()) {
		$('input[name="' + $(this).attr('name') + '"]').attr('disabled', 'disabled');
	} else {
		$('input[name="' + $(this).attr('name') + '"]').removeAttr('disabled');
	}
}

function updateSelectedValues(shouldSubmitForm) {
	var attr_id = $(this).attr('data-attr-id');
	$(this).parent().hide();
	$('#selected_values_' + attr_id).find('div').show();
	var values = $(this).prevAll('select:first').find('option:selected').map(function() {
		return $(this).html()
	}).join(', ');
	$('#selected_values_' + attr_id + ' .selected').attr('title', values)
        if (values == ''){
          values = '<no filter>';
	  $('#selected_values_' + attr_id + ' .selected').html('&lt;no filter&gt;&nbsp;');
        }else{
           $('#selected_values_' + attr_id + ' .selected').html(values);
        }
         var html = 'edit';
        if (values == '<no filter>')
        {
            html = 'add';
        }
	var add_link = "<br/><a id='f_" + attr_id + "' data-attr-id='" + attr_id + "' class='ignore-pending' href='#'>"+html+"</a>";
	$('#selected_values_' + attr_id + ' .selected').append(add_link);
	submitFilterForm($('#selected_values_' + attr_id + ' .selected').parents('form:first'));
	return false;
}

function submitFilterForm(form) {
	mergeFilters(form)
	disableForm(form);
}

function openFilters() {
	var selectedElements = '';
	$('.selected_filters').each(function(index) {
		if($(this).text() != '') {
			selectedElements += index
		}
	});
	$('#filter_form').find('select').each(function(index) {
		if($(this).val() != '') {
			selectedElements += index
		}
	});
	if(selectedElements != '') {
		$(".filterSection").trigger("onclick");
	}
	if($("#moreFilters").find('#activity_id').val() != '' || $("#f_activity_id").text() != '') {
		$(".moreFilters").trigger("onclick");
	}
}

function mergeFilters(filterForm) {
	$.each(FilterIds, function(index, value) {
		filterLabels = ''
		filterLabels += $("#filters_" + value + "_").find('option:selected').map(function() {
			return $(this).html()
		}).join(', ');
		if(filterLabels != '') {
			filterField = '<input type="hidden" class="filterField" name="used_filters[' + value + '][]" value="' + filterLabels + '" />';
			filterForm.append(filterField);
		}
	});
}

function disableForm(form) {
	$.ajax({
		type : "POST",
		data : $('#filter_form').serialize(),
		url : $('#filter_form').attr('action'),
		success : function(data) {
			$("#plan_results").html(data);
			open_close_filters();
			form.find('select').removeAttr('disabled');
			form.find('input').removeAttr('disabled');
		}
	});
}

function toggleMoreFilters(clickedLink) {
	var rel = clickedLink.attr('rel')
	var title = clickedLink.html();
	clickedLink.html(rel);
	clickedLink.attr('rel', $.trim(title));
	toggleElem(clickedLink.attr('class'));
}

function showLinks(selectList) {
	selectList.parent().find('a.hide:first').show();
	return false;
}

function cancel_select() {
	$(this).prevAll('select:first').val('');
	var attr_id = $(this).prevAll('select').attr('data-attr-id');
	$("#selected_values_" + attr_id).find('.selected').show();
	var values = $(this).parents('div').prevAll('div:first').children('div').find('span:first').text().split(',');

	if(attr_id == 'requestor_id' || attr_id == 'owner_id') {
		var count = 0;
		var arr = new Array();

		for(var i = 0; i < values.length / 2; i++) {
			arr[i] = '';
		}

		$.each(values, function(index, value) {
			if(index % 2 != 0) {
				arr[count] = arr[count] + value;
				count++;
			} else {
				arr[count] = arr[count] + value + ",";
			}
		});
		var tempArray = new Array();

		$.each(arr, function(index, value) {
			tempArray.push(jQuery.trim(value));
		});
		$("#filters_" + attr_id + '_').val(tempArray);
	} else {
		tempArray = [];
		$.each(values, function(index, value) {
			tempArray.push(jQuery.trim(value));
		});
		$("#filters_" + attr_id + '_').val(tempArray);
	}

	$(this).parents("div:first").find("select").hide();
	$(this).parents("div:first").find('.cancel_select').hide();
	$(this).parents("div:first").find('.hide').hide();

	return false;
}

function open_close_filters() {
	/* Open - 1, Closed - 0*/
	var f_state = $("#filter_block_collapse_state_flag").val();
	if(f_state == '1') {
		$("#filter_form").parent('div').parent('div').show();
        $("#close_request_filters").html("Close Filters");
	} else {
		$("#filter_form").parent('div').parent('div').hide();
        $("#close_request_filters").html("Open Filters");
	}
}

function remove_deleted_option() {
	$("#filters_aasm_state_ option[value='deleted']").hide();
}

function unselectSelectedFilterValues() {
    var attr_id = $(this).attr('data-attr-id');
    $('#filters_' + attr_id + '_').remove('.filter_hidden');
    $('#filters_' + attr_id + '_').clearFields();
    $('#done_' + attr_id).show();
    return false;
}
