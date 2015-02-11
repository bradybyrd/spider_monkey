////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
//= require filters
//= require jquery.contextMenu

var ReportsDiagram = {
  eventById: function (id) {
    var event = null;
    chart_deploymentWindowCalendar.getJSONData()['tasks']['task'].forEach(function (item) {
      if (item.event_id == id) {
        event = item;
      }
    });
    return event;
  },

  ContextMenu: {
    diagramSelector: 'body.reports .chart',

    show: function(event_id, series) {
      this.target = ReportsDiagram.eventById(event_id);
      this.permitted_actions = JSON.parse(this.target.permitted_actions);
      this.series = (series == 1);
      if (this.target && !this.__menuDisabled()) {
        this.$diagram.contextMenu(this.coordinates);
      }
    },

    __menuDisabled: function() {
      return this.permitted_actions.length == 0;
    },

    __cannot: function (action) {
      return $.inArray(action, this.permitted_actions) < 0;
    },

    init: function() {
      var _this = this;

      this.$diagram = $(this.diagramSelector);

      $(document).on('mouseup', function($event) {
        _this.coordinates = { x: $event.clientX, y: $event.clientY };
      });

      $.contextMenu({
        selector: this.diagramSelector,
        trigger: 'none',
        callback: function(key, options) {
          var m = "clicked: " + key;
          window.console && console.log(m) || alert(m);
        },
        items: {
          "edit": {
            name: "Edit",
            callback: function () {
                var popup_type = _this.series ? 'edit_series' : 'edit';
                url = url_prefix + '/environment/metadata/deployment_window/events/' +
                    _this.target.event_id + '/popup?popup_type=' + popup_type;
                $.facebox({ajax: url});
            },
            disabled: this.__cannot.bind(this)
          },
          "schedule": {
            name: "Schedule Request",
            className: 'schedule',
            callback: function () {
                url = url_prefix + '/requests/schedule_from_event' +
                    '?event_id=' + _this.target.event_id
                $.facebox({ajax: url})
            },
            disabled: this.__cannot.bind(this)
          }
        }
      });
    }
  }
};

$(document).ready(function() {
  if (!$("#report_type").length) {// if page does not have report due to permissions
    return;
  }
  ReportsDiagram.ContextMenu.init();

  $('body').on('click', "#show_filter", function() {
    $.get(url_prefix + "/reports/toggle_filter", {"open_filter":true}, function(no_data){
    });
    $(this).replaceWith('<a href="#" class="filter_link" id="hide_filter">Close Filters</a>');
    $('#filterSection').show();
  });

  $('body').on('click', "#hide_filter", function() {
    $.get(url_prefix + "/reports/toggle_filter", {"open_filter":0}, function(no_data){
    });
    $(this).replaceWith('<a href="#" class="filter_link" id="show_filter">Open Filters</a>');
    $('#filterSection').hide();
  });

  $('a.change_year').click(function() {
    $('#year').val($(this).attr('rel'));
    $('#year').parents('form:first').submit();
  });

  $('#show_all').click(function() {
    var form = $('#resource_gap_filter');
    form.find('option:selected').attr('selected', false);
    form.submit();
  });

  $('.factor_select').change(function() { show_factors(this.id) });
  $('.chart_type').change(function() { show_chart_criteria(this.id) });

  $('form.chart_data .submit input').click(function() {
    $(this).parents('form:first').ajaxSubmit(function(data) {
      $('#charts').html(data);
    });
    // $.ajax({url: '/reports/criteria?' + $(this).parents('form:first').serialize(), success:function(data) {$('#criteria').html(data);}});
    return false;
  });

  $('#all_apps_and_environments').change(toggle_app_and_environment_selects);
  function show_chart_criteria(el) {
    if (el == 'chart_trend') {
      single_factor();
      $('#trend_options').show();
    } else {
      $('#trend_options').hide();
    }
  }

  function show_factors(el) {
    if (el == 'chart_factor_single') {
      single_factor();
    } else {
      two_factor();
    }
  }

  function single_factor() {
    $('#chart_two_factor').hide();
    $('#trend_options').hide();
  }

  function two_factor() {
    $('#chart_two_factor').show();
  }

  function toggle_app_and_environment_selects() {
    disabled_val = $(this).attr('checked');
    $('#app_id').attr('disabled', disabled_val);
    $('#env_id').attr('disabled', disabled_val);
  }

  $('.view_by_env_group').hide();

  $('.mar_0').click(function() {
    if($(this).attr('env') == 'env_group'){
      $('.view_by_env').hide();
      $('.view_by_env_group').show();
      $('select#filters_environment_id').attr('disabled', true);

    } else{
      $('.view_by_env_group').hide();
      $('.view_by_env').show();
      $('select#filters_environment_id').attr('disabled', false);
    }
  });

  $('body').on('change', '#filters_group_on', function() {
    if ($("#report_type").val() != 'problem_trend_report'){
      form = $(this).parents('form:first');
      submit_report_filter(form);
    }
  });


  $(window).resize(function() {
    var screen_res_width = $('#content_box').width();
    var report = document.getElementById("report_type").value;
    if (report == "release_calendar" || report == "environment_calendar" || report == 'deployment_windows_calendar') {
      $.ajax({url: $('#report_filter_form').attr('action'),
             data: $('#report_filter_form').serialize()+'&width='+screen_res_width+'&r=1',
             success: function(result){
              $("#chart_partial").html(result);
            }});
    }
    else
    {
      $.ajax({url: $('#report_filter_form').attr('action'),
             data: $('#report_filter_form').serialize()+'&width='+screen_res_width+'&q=1',
             success: function(result){
              $("#chart_partial").html(result);
            }});
    }

    document.getElementById("screen_resolution").value = screen_res_width;

  });


  //  var screen_res_width = window.innerWidth != null? window.innerWidth: document.body != null? document.body.clientWidth:null;  // This gets width of current browser window.
  var report = document.getElementById("report_type").value;
  if (report == "release_calendar" || report == "environment_calendar" || report == 'deployment_windows_calendar') {
    var screen_res_width = $('#content_box').width();
    // if (screen_res_width != document.getElementById("screen_resolution").value) {
      $.ajax({
        url: $('#report_filter_form').attr('action'),
        data: $('#report_filter_form').serialize() + '&width=' + screen_res_width + '&r=1',
        success: function(result){
          $("#chart_partial").html(result);
        }
      });
      document.getElementById("screen_resolution").value = screen_res_width;
    // }
  }
  else
  {
    var screen_res_width = $('#content_box').width();
    if (screen_res_width != document.getElementById("screen_resolution").value) {
      $.ajax({
        url: $('#report_filter_form').attr('action'),
        data: $('#report_filter_form').serialize() + '&width=' + screen_res_width + '&q=1',
        success: function(result){
          $("#chart_partial").html(result);
        }
      });
      document.getElementById("screen_resolution").value = screen_res_width;
    }
  }
});

function ShowDateField(){
  var period = $("#period").val();
  period = period.replace(/[^A-Za-z]/g, '')
  var duration = ["lastweek", "lastweeks", "lastmonth", "lastmonths", "lastyear"];
  jQuery.each(duration, function(index, p){
    if (p == period){
      $("#" + p).show();
    } else {
      $("#" + p).hide();
    }
  });
}

function openReportForm(report){
  $.facebox(function() {
    $.get($("a[href*='" + report + "']:first").attr("href"), function(data) { $.facebox(data) })
  });
}

function displayRequests(request_ids){
  $.post(url_prefix + "/reports/requests", {"request_ids[]":request_ids}, function(request_list){
    $("#requests_list").html(request_list);
    $("#requests_list").scrollTo(500);
  });
}

function reset_filter_session(){
  $('select option').each(function () {
    $(this).removeAttr('selected');
  });
  $('input#beginning_date, input#end_date').val('');
  $('#filters_beginning_of_calendar, #filters_end_of_calendar').val('');
  $.get(url_prefix + "/reports/set_filter_session", {"reset_filter_session":true}, function(no_data){
  });
}

function submit_report_filter(form){
  $.ajax({
    type: "GET",
    data: $('#report_filter_form').serialize(),
    url: $('#report_filter_form').attr('action'),
    success: function(data) {
      window.location = url_prefix + "/reports/process?report_type="+$("#report_type").val();
    }
  });
}

function page(direction){
  $.ajax({url: $('#report_filter_form').attr('action'),
         data: $('#report_filter_form').serialize()+'&p='+direction,
         success: function(result){
          $("#chart_partial").html(result);
        }});

}
