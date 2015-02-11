////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
$(function() {
  $('body').on('click', 'div.filter_selected_values a', showFilterMultiSelect);
  $('body').on('click', 'div.filter_values_to_select a.filter_done', updateSelectedFilterValues);
  $('body').on('click', 'div.filter_values_to_select a.filter_cancel_select', cancelFilterSelect);
  $('body').on('click', 'div.filter_values_to_select a.filter_clear', clearSelectedFilterValues);
  $('body').on('click', 'a.clear_model_filters', clearAllFilters);
});

function clearAllFilters() {
  var form = $("#filter_form");
  form.find('select').val('');
  $('input#clear_filter').attr('value', '1');
  submitFilterFormLocal(form);
  return false;
}

function submitFilterFormLocal(form) {
  var assigned_tickets = [];
  var data_prm = '';
  if ($('#selected_tickets_section_for_form').children('input').length > 0) {
    $('#selected_tickets_section_for_form').children('input').each(function() {
      assigned_tickets.push($(this).val());
    });
  }
  if (assigned_tickets.length > 0) {
    data_prm = $('#filter_form').serialize() + "&current_tickets=" + assigned_tickets;
  } else {
    data_prm = $('#filter_form').serialize();
  }
  $.ajax({
    type: "GET",
    data: data_prm,
    url: $('#filter_form').attr('action'),
    success: function(data) {
      $("#modelFilterSection").parent('div').html(data);
    }
  });
}

function cancelFilterSelect() {
  $(this).prevAll('select:first').val('');
  var attr_id = $(this).prevAll('select').attr('data-attr-id');
  $("#filter_selected_values_" + attr_id).find('.selected').show();
  var values = $(this).parents('div').prevAll('div:first').children('div').find('span:first').text().split(',');

  tempArray = [];
  $.each(values, function(index, value) {
    tempArray.push($.trim(value));
  });
  $("#filters_" + attr_id + '_').val(tempArray);

  $(this).parents("div#filter_values_to_select_" + attr_id).hide();
  return false;
}

function clearSelectedFilterValues() {
  var attr_id = $(this).attr('data-attr-id');
  $('#filters_' + attr_id + '_').remove('.filter_hidden');
  $('#filters_' + attr_id + '_').clearFields();
  return false;
}

function showFilterMultiSelect() {
  var attr_id = $(this).attr('data-attr-id');
  $('#filter_values_to_select_' + attr_id).show();
  $(this).parents('div').next('div').find('select').show();
  $(this).parents('div').next('div').find('a.filter_cancel_select').show();
  $(this).parent().hide();
  return false;
}

function updateSelectedFilterValues(should_submit) {
  var attr_id = $(this).attr('data-attr-id');
  $(this).parent().hide();
  $('#filter_selected_values_' + attr_id).find('div').show();
  var values = $(this).prevAll('select:first').find('option:selected').map(function() {
    return $(this).html()
  }).join(', ');
  $('#filter_selected_values_' + attr_id + ' .selected').html(values);
  if (values == '')
    values = '<no filter>'; // FIXME: internationalize in a proper way
  $('#filter_selected_values_' + attr_id + ' .selected').attr('title', values)

  var br = '<br/>';
  var html = 'edit';
  if (values == '<no filter>') {
    br = '';
    html = 'add';
  }

  var add_link = br + "<a id='f_" + attr_id + "' data-attr-id='" + attr_id + "' class='ignore-pending' href='#'>" + html + "</a>"
  $('#filter_selected_values_' + attr_id + ' .selected').append(add_link);
  submitFilterFormLocal($('#filter_selected_values_' + attr_id + ' .selected').parents('form:first'));
  return false;
}

function setFiltersSection() {
  var state = $("#filters_collapse_state").attr("value");
  if ((state != undefined) && (state == 'Open')) {
    $("#filter_form").parent('div').parent('div').show();
    $("#toggleFilterLink").find('a').html("Close Filters");
    $("#toggleFilterLink").find('a').attr("rel", "Open Filters");
    $("#filters_collapse_state").attr("value", "Open");
  } else {
    $("#filter_form").parent('div').parent('div').hide();
    $("#toggleFilterLink").find('a').html("Open Filters");
    $("#toggleFilterLink").find('a').attr("rel", "Close Filters");
    $("#filters_collapse_state").attr("value", "Closed");
  }
}

function toggleFiltersSection() {
  var state = $("#filters_collapse_state").attr("value");
  var html = $("#toggleFilterLink").find('a').html();
  var rel = $("#toggleFilterLink").find('a').attr("rel");
  $("#toggleFilterLink").find('a').html(rel);
  $("#toggleFilterLink").find('a').attr("rel", html);
  if ((state != undefined) && (state == 'Open')) {
    $("#filters_collapse_state").attr("value", "Closed");
    $("#filter_form").parent('div').parent('div').hide();
  } else {
    $("#filters_collapse_state").attr("value", "Open");
    $("#filter_form").parent('div').parent('div').show();
  }
  submitFilterFormLocal();
}

function setInitialFilters(filters) {
  $("select").each(function(index) {
    if (filters != undefined) {
      var value = $(this).attr('data-attr-id');
      if (filters[value] != undefined) $(this).val(filters[value]);
      var values = $(this).find('option:selected').map(function() {
        return $(this).html()
      }).join(', ');
      if (values != '') {
        var valtag = '<span class="multivalues">' + values + '&nbsp;</span>'
        $("#filter_selected_values_" + value).find('.selected').prepend(valtag).find('a').html('edit');
        $("#filter_selected_values_" + value).next('div').find('a.filter_clear').show();
      } else {
        $("#filter_selected_values_" + value).find('.selected').prepend('&lt;no filter&gt;&nbsp;');
        $("#filter_selected_values_" + value).next('div').find('a.filter_clear').hide();
      }
    }
  });
}
