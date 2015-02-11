////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
  $('body').on('change', '#activity_category_id', getCreationAttributes);
  $('body').on('click', 'span.selected_values a', showMultiSelect);
  $('body').on('click', 'span.values_to_select a.hide', updateSelectedValues);
  $('body').on('click', 'span.values_to_select a.clear', clearSelectedValues);
  $('body').on('change', 'span.values_to_select select', toggleBlankSubmission).livequery(function() { $(this).change() });

  if ($('#request_button').val() != undefined) {
	hideUpdateButton();
  }

  var formatCallback = function() {
    extractNumber(this, 0, true);
    // $(this).val(formattedCurrencyString($(this).val()));
    formatInput.apply(this);
  }
  $('body').on('blur', 'input.currency', formatCallback).on('keyup', 'input.currency', formatCallback).on('keypress', 'input.currency', function(e) {
    return blockNonNumbers(this, e, true, true);
  });

  $('body').on('change', 'input.persist', function() {
    $('div.widget.phases').data($(this).attr('id')+'-value', $(this).val());
  });

  // $("form.activity").preventLeavingWhenChanged();
  $('form.activity').submit(function(e) { warnAboutResources(e); });

  $('a#create_consolidated_request').click(function() {
    var form = $('#create_consolidated_request_form');
    if ($('input.request_ids:checked').size() > 0) {
        $('input.request_ids:checked').each(function() {
          var id_field = $('<input type="hidden" name="request_ids[]" />');
          id_field.val($(this).val());
          form.append(id_field);
        });
        $('#create_consolidated_request_form').submit();
    } else {
        alert('Please select requests from the list to consolidate them.');
    }
    return false;
  });

  function filterInput(e) {
    // Command/Control, return, or tab
    if (e.metaKey || e.which == $.ui.keyCode.ENTER || e.which == $.ui.keyCode.TAB) return true;

    var value = $(this).val().replace(/\D/g, '');
    if (e.which >= 48 && e.which <= 57) // 0-9
      value += e.which - 48;
    else if (e.which == $.ui.keyCode.BACKSPACE)
      value = value.slice(0, value.length - 1);

    $(this).val('$' + formattedCurrencyString(value));

    return false;
  }

  function formatInput() {
    $(this).val('$' + formattedCurrencyString($(this).val()));
    updateCurrencyHelper($(this));
  }

  function formattedCurrencyString(value) {
    if (value == 0 || value == '0') {
    var numtrim = Math.round(value).toString().replace(/[\$,]/g, '');
    }
    else {
    var numtrim = value.toString().replace(/[\$,]/g, '');
    }
	return numtrim.replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,');
  }
  StreamStep.formattedCurrencyString = formattedCurrencyString;

  function updateCurrencyHelper(input) {
    var helper = $('input.currency_helper[name="' + input.attr('name') + '"]');
    helper.val(input.val().replace(/[^0-9-]/g, ''));
  }

  function showMultiSelect() {
    var attr_id = $(this).attr('data-attr-id');
    $('#values_to_select_' + attr_id).show();
    $(this).parent().hide();
    return false;
  }

  function toggleBlankSubmission() {
    if ($(this).val()) {
      $('input[name="' + $(this).attr('name') + '"]').attr('disabled', 'disabled');
    } else {
      $('input[name="' + $(this).attr('name') + '"]').removeAttr('disabled');
    }
  }

  function updateSelectedValues() {
    var attr_id = $(this).attr('data-attr-id');
    $(this).parent().hide();
    $('#selected_values_' + attr_id).show();

    var values = $(this).prevAll('select:first').find('option:selected').map(function() { return $(this).html() }).join(', ');
		$('#selected_values_' + attr_id + ' .selected').attr('title', values)
		values = values.substring(0, 47);
    if (values.length >= 47){ values += '...'}
		$('#selected_values_' + attr_id + ' .selected').html(values);
    return false;
  }

  function clearSelectedValues() {
    $(this).prevAll('select:first').val('').change();
    return false;
  }

  function getCreationAttributes() {
    $.get($(this).attr('data-template-url') + '?activity_category_id=' + $(this).val(), function(html) {
        $('#activity_creation_attributes').html(html);
      });
  }


  function isClosedStatus(status, closedRE) {
    return closedRE.exec(status) ? true : false;
    // return closedRE.exec(status.toLowerCase()) ? true : false; BJB Case Sensitive
  }

  function warnAboutResources(e) {
    var currentStatus = $('#activity_status').val() || false;
    var oldStatus = $('#old_status').val() || false;
    var closedStatuses = $('#closed_statuses').val() || false;
    if (currentStatus && oldStatus && closedStatuses) {
      var closedRE = new RegExp("^(" + closedStatuses + ")$");
      if (isClosedStatus(currentStatus, closedRE) && ! isClosedStatus(oldStatus, closedRE)) {
        var proceed = confirm("Warning: " +
                              "Changing the status will remove any resources assigned to this activity?");
        if (! proceed) {
          e.preventDefault();
        }
      }
    }
  }
});

  function display_contact_impact_section(checkBox){
		if (checkBox.attr('checked')){
			$('#project_delivery_date').show();
			$('.' + checkBox.attr('id')).show();
		} else {
			$('#project_delivery_date').hide();
			$('.' + checkBox.attr('id')).hide();
		}
		
	}
	
	function loadRequests(plan_id, activity_id){
		var requests_td = $("#"+ plan_id + "_activity_" + activity_id);
		if (requests_td.is(':hidden')){
			if (requests_td.html() == ''){
				$.get(url_prefix + '/activities/' + activity_id + '/load_requests', function(partial){
	    		requests_td.html(partial);
					requests_td.show();
	    	});
			} else {
				requests_td.show();
			}
		} else {
			requests_td.hide();
		}
	}
	
	function hideUpdateButton(){
	  $('#update_button').hide();
	}
