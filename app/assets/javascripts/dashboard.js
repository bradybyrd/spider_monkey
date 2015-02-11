////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

FilterIds = ['aasm_state', 'activity_id', 'app_id', 'package_content_id',
    'environment_id', 'requestor_id', 'owner_id', 'server_id', 'user_id',
    'release_id', 'team_id', 'delivered', 'organizational_impact', 'leading_group_id',
    'component_id', 'work_task_id', 'business_process_id','assignee_id','group_id','plan_run_id',
    'plan_id', 'plan_aasm_state', 'automation_category', 'automation_type', 'render_as',
    'deployment_window_series_id', 'inbound_outbound'];

$(document).ready(function(){
    if($('a#viewCurrentStepsResources').attr('href') == "/steps/currently_running"){
        $('a#viewCurrentStepsResources').attr('href', "/steps/currently_running?should_user_include_groups=true");
    }

 if($("#default_tab_field").attr("value") == 'Calendar')
  {     $('ul.dashboard_request_tab.dashboard_request_tab li').removeClass('current');
     $('ul.dashboard_request_tab.dashboard_request_tab li').eq(1).addClass('current');
            if($("#request_and_calendar").length>0)
                domElement=$("#request_and_calendar");
            else
                domElement=$("#content_box");
            domElement.load($('ul.dashboard_request_tab.dashboard_request_tab li a').eq(1).attr('href'), function() {
                        $(".calendar_fields").hide();
	    open_close_filters();
clearDuplicateIds();
     });
  }


});

$(function() {
    initialTabLoad();

    open_close_filters();

    $('body').on('click', '#show_deleted, #hide_deleted, #hide_request_steps', function(event) {
        event.preventDefault();
        elementToggler(this, event);
    });

    $('body').on('click', '#show_request_steps', function(event) {
      event.preventDefault();
      var steps_are_loaded = false;
      if( !steps_are_loaded ){
        steps_are_loaded = true;
        $('.request_row').each(function(){
          var request_row_id = $(this).attr('id');
          var request_id = request_row_id.split('_')[2];
          var request_row = $(this);
          var filter_var = $("#show_request_steps").attr('rel')
          if (!request_row.next().hasClass('request_steps')){
            $.get('dashboard/steps_for_request_ajax', {
              'request_id' : request_id,
              'session_filter_var' : filter_var
            }, function(partial){
              request_row.after(partial);
            });
          }else{
            $('.request_steps').each(function(){
              var step_row = $(this);
              step_row.show();
            });
          }
        });
      }
      elementToggler(this, true);
    });

    function defaultTabLink() {
      var defaultTab = $('#default_tab_field').val();
      return $('body.dashboard .dashboard_request_tab')
        .find('li' + (defaultTab != '' ? ':contains(' + defaultTab + ')' : '') + ':first')
        .children('a');
    }

    function initialTabLoad() {
      var link = defaultTabLink();
      if (link.length == 0) {
        return;
      }
      var href_val = link.attr('href');
      var href = new String(href_val);
      var temp = 0;

      if(href.indexOf("dashboard") != -1 || href.indexOf("plan") != -1 ){
          temp = 1;
      }

      var tab_name = link.html();
      $('.all_steps').show();
      $('.filterSection').show();
      link.parent().siblings().removeClass('current');
      link.parent().addClass("current");
      $(".calendar_fields").show();

      if((tab_name == "Calendar" && temp != 1) || tab_name == "Requests" ) {
      } else {
        if($("#request_and_calendar").length>0)
          domElement = $("#request_and_calendar");
        else
          domElement = $("#content_box");
          domElement.load(hrefWithPageParameters(link.attr('href')), function() {
            if (tab_name == 'Currently Running Steps') {
              $('.all_steps').hide();
            }
            $(".calendar_fields").hide();
            open_close_filters();
            clearDuplicateIds();
            tablesorterTableHeaderArrowAssignment();
          });
      }
    };

    function hrefWithPageParameters(href) {
      querystring = document.URL.split("?")[1];
      if (href.indexOf("?") >= 0) {
        return(href + "&" + querystring);
      } else {
        return(href + "?" + querystring);
      }
    }

    $('body').on('click', 'ul.dashboard_request_tab li a', function(event) {
        var href_val = $(this).attr('href');
        if (href_val == '/resources' || href_val == '/my_resources' ){
            return;
        }
        var href = new String(href_val);
        var temp = 0;

        if(href.indexOf("dashboard") != -1 || href.indexOf("plan") != -1 ){
            temp = 1;
        }

        var tab_name = $(this).html();
        $('.all_steps').show();
        $('.filterSection').show();
        $(this).parent().siblings().removeClass('current');
        $(this).parent().addClass("current");
        $(".calendar_fields").show();

        if((tab_name == "Calendar" && temp != 1) || tab_name == "Requests" ) {
        } else {
            event.preventDefault();
            if($("#request_and_calendar").length>0)
                domElement=$("#request_and_calendar");
            else
                domElement=$("#content_box");
                domElement.load($(this).attr('href'), function() {
                if (tab_name == 'Currently Running Steps') {
                    $('.all_steps').hide();
                }
                $(".calendar_fields").hide();
                open_close_filters();
                clearDuplicateIds();
                tablesorterTableHeaderArrowAssignment();
            });
        }
    });

    $('body').on('click', 'div.pagination a', function(event){
        event.preventDefault();
        var href = $(this).attr("href");
        $.get($(this).attr("href"), function(data){
            $("#request_and_calendar").html(data);
            clearDuplicateIds();
            open_close_filters();
        });
    });

    $('body').on('click', 'div.selected_values a', showMultiSelect);

    $('body').on('click', 'div.values_to_select a.hide', updateSelectedValues);

    $('body').on('click', 'div.values_to_select a.clear', clearSelectedValues);

    $('div.values_to_select select').livequery(function(){
        $(this).change(toggleBlankSubmission).change();
    });

    $('body').on('click', 'div.values_to_select a.cancel', updateSelectedValues);

    $('body').on('change', 'div.values_to_select select', function() {
        showLinks($(this));
    });

    $('.requestList').find('th').each(function() {
        if (/Participants/.test($(this).text())) {
            $(this).removeClass("sortable")
        }
    });

    $('body').on('click', 'a.cancel_select', cancel_select);

    $('div.request').livequery(function(){
        $(this).tooltip({
          delay: 420
        });
    });
    $('body').on('change', '#date', function() {
        var url = url_prefix + "/calendars/" + $('.calendar_formate_links #display_format').val();
        var d = $(this).datepicker( "getDate" )
		var form = $("#filter_form");
        var dateString = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();

        $.ajax({
            type: "GET",
            data: form.serialize()+'&beginning_of_calendar='+dateString,
            url: url,
            success: function(data) {
                $("#request_and_calendar").html(data);
                open_close_filters();
                $('select#date_start').find('option:selected').removeAttr('selected');
                $('select#date_start').find('option[value="' + (d.getMonth() + 1) + '"]').attr('selected', 'selected')
            }
        });
        return false;
    });
    $('body').on('change', '#date_upcoming_requests', function(){
        var url = url_prefix + "/calendars/" +'upcoming-requests'
        var d = $(this).datepicker( "getDate" )
		var form = $("#filter_form");
        var dateString = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();

        $.ajax({
            type: "GET",
            data: form.serialize()+'&beginning_of_calendar='+dateString,
            url: url,
            success: function(data) {
                $("#request_and_calendar").html(data);
                open_close_filters();
            }
        });
        return false;
    })



    $('body').on('change', '.calendar_formate_links #display_format', function() {
        $('input#hidden_display_format').val($(this).val());
        var form = $("#filter_form")
        var action;
        var flag = false;
        if(form.attr('action').indexOf("dashboard") != -1 ) {
            action = url_prefix + "/calendars/dashboard/" + $(this).val();
        } else {
            action = url_prefix + "/calendars/" + $(this).val();
            if($("#planFlag").attr('id') != "planFlag") {
                flag = true;
            }
        }
        $.ajax({
            type: "GET",
            data: form.serialize(),
            url: action,
            success: function(data) {
                $("#request_and_calendar").html(data);
                open_close_filters();
                if(flag == true) {
                    $("#request_calendar_sidebar").show();
                    $(".calendar_fields").html($("#request_calendar_sidebar"));
                }
            }
        });
        return false;
    });

    $('body').on('change', 'div#sidebar div.calendar_fields div.calendar_formate_links div.calendar_option_field select#date_start', function() {
        $('input#hidden_date_start').val($(this).val());
        var form = $("#filter_form");
        var action;
        form.append('<input type="hidden" name="page_path" value="1"/>')

        if($('input[name=view_type]:checked', '#select_view_type').val().indexOf("upcoming-requests") == -1) {
            action = form.attr('action');
        } else {
            action = $('input[name=view_type]:checked', '#select_view_type').val();
        }

        $.ajax({
            type: "GET",
            data: form.serialize(),
            url: action,
            success: function(data) {
                $("#request_and_calendar").html(data);
                open_close_filters();
            }
        });
        return false;
    });


    $('body').on('submit', '#dashboard_range', function() {
       $('#beginning_of_calendar, #filters_beginning_of_calendar').val($('#beginning_date').val());
        $('#end_of_calendar, #filters_end_of_calendar').val($('#end_date').val());
        if ($('#beginning_date').val().length > 0 || $('#end_date').val().length > 0 ) {
            $.ajax({
                type: "GET",
                data: $('#filter_form, #report_filter_form').serialize(),
                url: $('#filter_form, #report_filter_form').attr('action'),
                success: function(data) {
                  if ($("#request_and_calendar").length > 0){
                    $("#request_and_calendar").html(data);
                    clearDuplicateIds();
                    open_close_filters();
                    $('#filter_form').find('select').removeAttr('disabled');
                    $('#filter_form').find('input').removeAttr('disabled');
                  } else {
                    var report_type = $("#report_type").val();
                    if ( report_type === 'deployment_windows_calendar' ){ // nah... Plenty to refactor to make it work without this 'if'
                      window.location = url_prefix + "/reports/" + report_type;// + "?width=" + $("#screen_resolution").val();
                    } else {
                      window.location = url_prefix + "/reports/process?report_type=" + report_type + "&width=" + $("#screen_resolution").val();
                    }
                  }
                }
            });
            return false;
        } else {
            alert("Please Select a Valid Date Range.");
            return false;
        }
    });

    $('body').on('change', '.request_filters', function() {
        var form = $(this).parents('form:first');
        var td = $(this).parents('td:first');
        var selectListId = td.find('select').attr('id');
        var currentValue = $('#' + selectListId +  ' :selected').val();
        var currentValueText = $('#' + selectListId +  ' :selected').text();
        var divEl = td.find('div');
        var selectedValues = divEl.text();
        matched = new RegExp(currentValueText, "i").test(selectedValues);
        if (currentValue == '' || matched == false) {
            hiddenField = '<input type="hidden" name="temp_filter" value="1" />';
            form.append(hiddenField);
            mergeFilters(form);
            form.submit();
            form.find('select').attr('disabled', 'disabled');
            form.find('input').attr('disabled', 'disabled');
            $("#facebox_overlay").show();
        }
    });

    $('#viewCurrentStepsDashboard').bind('click', function(event) {
        event.preventDefault();
        $('.DashboardTabs').find('a').removeClass('current');
        $(this).addClass("current");
        $("#adjustMargin").load($('#viewCurrentStepsDashboard').attr('href'), function() {
            $('.all_steps').hide();
            $('.filterSection').hide();
        });
    });

    $('#viewCurrentStepsResources').bind('click', function(event) {
        event.preventDefault();
        $('.pageSection').find('li').removeClass('current');
        $(this).parents('li:first').addClass("current");
        $('.left .content').load($('#viewCurrentStepsResources').attr('href'), function() {
            $('.all_steps').hide();
            $('.requestFilters').hide();
        });
    });

    $('#viewCurrentStepsRequest').bind('click', function(event) {
        event.preventDefault();
        $('.pageSection').find('li').removeClass('selected');
        $(this).parents('li:first').addClass("selected");
        $('.left .content').load($('#viewCurrentStepsRequest').attr('href'), function() {
            $('.all_steps').hide();
            $('.filterSection').hide();
        });
    });

    $('.checkbox_request_filters').bind("change click keypress", function() {
        if (currentValue == '' || matched == false) {
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
            type: "GET",
            data: form.serialize(),
            url: form.attr('action'),
            success: function(data) {
                $("#request_and_calendar").html(data);
                form.find('select').removeAttr('disabled');
                form.find('input').removeAttr('disabled');
            }
        });
    });

    $('body').on('click', 'a.add_request_filters', function() {
        var filterForm = $(this).parents('form:first');
        var td = $(this).parents('td:first').prev();
        var selectListId = td.find('select').attr('id');
        var currentValue = $('#' + selectListId +  ' :selected').val();
        var currentValueText = $('#' + selectListId +  ' :selected').text();
        var divEl = td.find('div');
        var selectedValues = divEl.text();
        matched = new RegExp(currentValueText, "i").test(selectedValues);
        if (currentValue != '' && matched == false)	{
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
                //filterForm.submit();
                $.post($('#filter_form').attr('action'), $('#filter_form').serialize(), function() {
                    });
            }
        }
        return false;
    });

    $('.checkbox_request_filters').bind("change click keypress", function() {
        var form = $(this).parents('form:first');
        form.submit();
        form.find('select').attr('disabled', 'disabled');
        form.find('input').attr('disabled', 'disabled');
    });

    $('body').on('click', '.requestList th.sortable', function() {
        if ($('#filters_sort_scope').val() != $(this).attr('data-column')) {
            $('#filters_sort_direction').val('asc');
        } else {
            $('#filters_sort_direction').toggleValues('asc', 'desc');
        }

        $('#filters_sort_scope').val($(this).attr('data-column'));

        $.ajax({
            type: "GET",
            data: $('#filter_form').serialize(),
            url: $('#filter_form').attr('action'),
            success: function(data) {
                $("#request_and_calendar").html(data);
                clearDuplicateIds();
                open_close_filters();
                sortable_table_header_arrow_assignment();
            }
        });
    });

    $('body').on('click', 'a.clear_request_filters', function() {
        var form = $("#filter_form");
        $('#filter_form').find('select').attr('disabled', 'disabled');
        form.find('select').val('');
         $('#beginning_date').val('')
    $('#end_date').val('')
    $('#beginning_of_calendar').val('');
    $('#end_of_calendar').val('');
    $('#filters_inbound_outbound').val('');
		hiddenField = '<input type="hidden" name="clear_filter" value="1" />';
		form.append(hiddenField);
   		disableForm(form);
    return false;
    });

   $('body').on('click', 'a#close_request_filters', function() {
     /* Open - 1, Closed - 0*/
     var f_state = $('#filter_block_collapse_state_flag').val();
     if (f_state == '1'){
        $('#filter_block_collapse_state_flag').val('0');
     }else{
        $('#filter_block_collapse_state_flag').val('1');
     }
     var form = $("#filter_form");
     disableForm(form);
     return false;
    });
});

function setFilters(filters) {
	$.each(FilterIds, function(index, value) {
		if (filters != undefined) {
			$("#filters_" + value + "_").val(filters[value]);
			var values = $("#filters_" + value + "_").find('option:selected').map(function() { return $(this).html() }).join(', ');
			if (values != '' ){
				var valtag = '<span class="multivalues">' + values + '&nbsp;</span>'
				$("#selected_values_" + value).find('.selected').prepend(valtag).find('a').html('edit');
				$("#selected_values_" + value).next('div').find('a.clear').show();
			}else{
				$("#selected_values_" + value).find('.selected').prepend('&lt;no filter&gt;&nbsp;');
				$("#selected_values_" + value).next('div').find('a.clear').hide();
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
    if ($(this).val()) {
        $('input[name="' + $(this).attr('name') + '"]').attr('disabled', 'disabled');
    }else {
        $('input[name="' + $(this).attr('name') + '"]').removeAttr('disabled');
    }
}

function updateSelectedValues(shouldSubmitForm) {
  var attr_id = $(this).attr('data-attr-id');
  $(this).parent().hide();
  $('#selected_values_' + attr_id).find('div').show();
  var values = $(this).prevAll('select:first').find('option:selected').map(function() { return $(this).html() }).join(', ');
  if (values == '')
      values = '<no filter>'; // FIXME: internationalize in a proper way
	$('#selected_values_' + attr_id + ' .selected').attr('title', values)
	$('#selected_values_' + attr_id + ' .selected').html(values);
	var add_link = "<br/><a id='f_" + attr_id + "' data-attr-id='" + attr_id + "' class='ignore-pending' href='#'>add</a>"
	$('#selected_values_' + attr_id + ' .selected').append(add_link);
	submitFilterForm($('#selected_values_' + attr_id + ' .selected').parents('form:first'));
  return false;
}

function clearSelectedValues() {
  var attr_id = $(this).attr('data-attr-id');
  $('#filters_' + attr_id + '_').remove('.filter_hidden');
  $('#filters_' + attr_id + '_').clearFields();
  $('#done_' + attr_id).show();/*fixed for report filters... might having impact on other places */
  return false;
}

function submitFilterForm(form) {
	mergeFilters(form)
	disableForm(form);
}

function openFilters() {
	var selectedElements = '';
	$('.selected_filters').each(function(index) {
		if ($(this).text() != '') {selectedElements += index}
	});
	$('#filter_form').find('select').each(function(index) {
		if ($(this).val() != '') {selectedElements += index}
	});
	if (selectedElements != ''){$(".filterSection").trigger("onclick");}
	if ($("#moreFilters").find('#activity_id').val() != '' || $("#f_activity_id").text() != '') {
		$(".moreFilters").trigger("onclick");
	}
}

function mergeFilters(filterForm) {
  $.each(FilterIds, function(index, value) {
    filterLabels = ''
    filterLabels += $("#filters_" + value + "_").find('option:selected').map(function() { return $(this).html() }).join(', ');
    if (filterLabels != '') {
      filterField = '<input type="hidden" class="filterField" name="used_filters[' + value + '][]" value="' + filterLabels + '" />';
      filterForm.append(filterField);
    }
  });
}

function disableForm(form) {
  if ($("#select_view_type input[type='radio']:checked").val() != undefined && $("#select_view_type input[type='radio']:checked").val().indexOf("upcoming-requests") != -1) {
    $('#filter_form').attr("action", url_prefix + "/calendars/upcoming-requests");
  }
  $.ajax({
    type: "GET",
    data: $('#filter_form, #report_filter_form').serialize(),
    url: $('#filter_form, #report_filter_form').attr('action'),
    success: function(data) {
      if ($("#request_and_calendar").length > 0) {
        $("#request_and_calendar").html(data);
        clearDuplicateIds();
        request_count = $("#request_and_calendar").find('.request_pagination span:first').html();
        inbound_requests_count = $("#total_inbound_request").val();
        outbound_requests_count = $("#total_outbound_request").val();
        if (request_count != null) {
          var req_count_str = request_count.toString();
          if (req_count_str != '') {
            $("#request_count").html(req_count_str.replace(":", ""));
            $("#inbound_requests_count").html(inbound_requests_count);
            $("#outbound_requests_count").html(outbound_requests_count);
          }
        }
        open_close_filters();
        form.find('select').removeAttr('disabled');
        form.find('input').removeAttr('disabled');
        sortable_table_header_arrow_assignment();
      } else if ($("form").hasClass("script_filter")) {
        $('input#clear_filter').attr('value', '0');
        window.location = url_prefix + "/environment/automation_scripts"
      } else {
        if (document.body.className.match(/reports/)) {
            window.location.reload();
        } else {
            window.location = url_prefix + "/reports/process?report_type=" + $("#report_type").val() + "&width=" + $("#screen_resolution").val();
        }
      }
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

function updateRecentActivities(){
    // setInterval("fetchRecentActivities()", 120000);
}

/*
function  fetchRecentActivities(){
    if($("#facebox").is(':hidden')){
        loadRecentActivities()
    }
}
*/

function loadRecentActivities() {
	/*
    $.ajax({
        url: url_prefix + "/recent_activities?pagination=false",
        beforeSend: function(){
            hideLoader();
            $('#wait').show();
        },
        success: function(recent_activities) {
            if (recent_activities == "No recent activity found") {
            } else {
                $('#recent_activities_container').html(recent_activities)
                $('#recent_activities_container').show();
            }
        }
    });
	*/
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

    if(attr_id == 'requestor_id' || attr_id == 'owner_id')
    {
        var count = 0;
        var arr = new Array();

        for(var i = 0;i<values.length/2;i++)
        {
            arr[i] = '';
        }

        $.each(values, function(index, value) {
            if(index%2 != 0)
            {
                arr[count]= arr[count] + value;
                count++;
            }
            else
            {
                arr[count]= arr[count] + value+",";
            }
        });

        var tempArray = new Array();

        $.each(arr, function(index, value) {
            tempArray.push($.trim(value));
        });
        $("#filters_" + attr_id + '_').val(tempArray);
    }
    else
    {
        tempArray = [];
        $.each(values, function(index, value) {
            tempArray.push($.trim(value));
        });
        $("#filters_" + attr_id + '_').val(tempArray);
    }

    $(this).parents("div:first").find("select").hide();
    $(this).parents("div:first").find('.cancel_select').hide();
    $(this).parents("div:first").find('.clear').hide();
    $(this).parents("div:first").find('.hide').hide();

    return false;
}

function open_close_filters() {
   /* Open - 1, Closed - 0*/
    var f_state = $("#filter_block_collapse_state_flag").val();
    if (f_state == '1') {
         $("#filter_form").parent('div').parent('div').show();
    }else {
         $("#filter_form").parent('div').parent('div').hide();
    }
}

function remove_deleted_option() {
    $("#filters_aasm_state_ option[value='deleted']").hide();
}

function clearDuplicateIds()
{
    if($('#request_and_calendar > div').attr('id')=='request_and_calendar')
    {
        $('#request_and_calendar').replaceWith($('#request_and_calendar').contents())
    }

}
