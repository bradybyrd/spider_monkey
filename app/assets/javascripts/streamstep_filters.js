////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

function applyFilters(domElement){
	var form = domElement.parents('form:first');
  var td = domElement.parents('td:first');
  var selectListId = td.find('select').attr('id');
  var currentValue = $('#' + selectListId +  ' :selected').val();
  var currentValueText = $('#' + selectListId +  ' :selected').text();
  var divEl = td.find('div');
  var selectedValues = divEl.text();
  matched = new RegExp(currentValueText, "i").test(selectedValues);
  if (currentValue == '' || matched == false)
  {
  	hiddenField = '<input type="hidden" name="temp_filter" value="1" />';
		form.append(hiddenField);
		mergeFilters(form);
		form.submit();
    form.find('select').attr('disabled', 'disabled');
    form.find('input').attr('disabled', 'disabled'); 
	}
}

function addMoreFilters(domElement){
	var filterForm = domElement.parents('form:first');
  var td = domElement.parents('td:first');
  var selectListId = td.find('select').attr('id');
  var currentValue = $('#' + selectListId +  ' :selected').val();
  var currentValueText = $('#' + selectListId +  ' :selected').text();
  var divEl = td.find('div');
  var selectedValues = divEl.text(); 
  matched = new RegExp(currentValueText, "i").test(selectedValues);
  if (currentValue != '' && matched == false)
  {
  	if (selectedValues == '') {
  		currentValueText = currentValueText;
  	} else { 
  		currentValueText  = ', ' + currentValueText;
  	}
  	if (selectListId != '') {
  	divEl.append(currentValueText);
  	hiddenField = '<input type="hidden" class="filter_hidden" name="filters[' + selectListId + '][]" value="' + currentValue +  '" />';
  	filterForm.append(hiddenField);
  	$('#' + selectListId +  ' :selected').val('');
	  mergeFilters(filterForm);
		filterForm.submit();
  	}
	}
	return false;
}

function clearFilters(domElement){
	var form = domElement.parents('form:first');
  $('#filter_form').find('select').attr('disabled', 'disabled');
  form.find('select').val('');
	form.find('div').html('');
	hiddenField = '<input type="hidden" name="clear_filter" value="1" />';
	form.append(hiddenField);
  form.submit();
  return false;
}

function setFilters(filters) {
	var filterForm = $('#filter_form');
  $.each(FilterIds, function(index, value) { 
	  if (filters[value] != undefined) {
			selectedValues = []
			$.each(filters[value], function(i, v) {
				if ($("#" + value).val() != v){
					selectedValues.push($("#"+ value + " option[value='" + v + "']").text());
					$("#" + value + " option[value='" + v + "']").remove();
				}
			});
			var divText = selectedValues.join(', ');
			$('#' + value).parents('td:first').find('div').append(divText);
		}
	});
	filterForm.find('span').html('');
}

function mergeFilters(filterForm){
  $.each(FilterIds, function(index, value) { 
    filterLabels = ''
    filterLabels += $('#' + value +  ' :selected').text();
    filterLabels += $('#f_' + value).text();
    if (filterLabels != '') {
      filterField = '<input type="hidden" class="filterField" name="used_filters[' + value + '][]" value="' + filterLabels + '" />';
      filterForm.append(filterField);
    }
  });
}

function showSearchWarningMessage(){
	if (mygrid.getRowsNum() == 0){
		$("#expand_collapse").hide();
		if ($("#key").val() != "" ){
			if ($(".multivalues").length > 0){
				$("#search_warning_without_f").addClass("dn");
				$("#search_warning_with_f").removeClass("dn");
				$("#search_warning_with_f").append("<b>" + $("#key").val() + "</b>");
			} else {
				$("#search_warning_with_f").addClass("dn")
				var url = window.location.href;
				if (url.indexOf("activities") > 0){
					categories = [];
					$.each($(".pageSection div ul li").not(document.getElementsByClassName('selected')), function(){
						categories.push($(this).text());
					});
					$("#search_warning_without_f span").html(categories.join(", "));
				}
				$("#search_warning_without_f").removeClass("dn");
			}
		}
	}
}