////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
//= require select2
//= require moment

$(function () {

  CollapseRequestHeader();

  checkStepAlertInCookie();

  $('body').on('submit', '#request_message_form', function () {
    $.ajax({
      url: $('#request_message_form').attr("action"),
      type: "PUT",
      data: $('#request_message_form').serialize(),
      dataType: "text",
      success: function (data) {
        if (data == "error") {
          $("#message_body").addClass("fieldWithError");
          $(".content h2:first").html("<ul><li>Message can't be blank</li><ul>").css('color', '#FF0000').css("font-size", "120%");
        } else {
          window.location = data;
        }
      }
    });
    return false;
  });

  $('body').on('change', "#request_plan_member_attributes_plan_id", function () {
    load_plan_stages($(this));
  });

  $('body').on('click', '#collapse_request_header', function () {
    requestHeaderCookie('collapse');
    collapseRequestHeader();
    return false;
  });

  $('body').on('click', '#expand_request_header', function () {
    requestHeaderCookie('expanded');
    expandRequestHeader();
    return false;
  });

  $('body').on('click', 'div.request_details a.clear_list, form#new_request a.clear_list', function () {
    if ($('select#request_app_ids').find('option class="clicked"')) {
      $('#request_app_ids option').removeClass('clicked').css({'background-color': '#FFF'});
    }
  });

  // $("#request_title").always().click(function(event){
  //
  //     event.preventDefault();
  // 		showLoader();
  //     $('#steps_container').load($('#request_title').attr('href'), function(){
  //       $('.content #viewSelectedTabs').show();
  //       $('.content #collapse_request_link').show();
  //       $('#request_header_expanded').show();
  //       $('.content #view_request').show();
  // 			var isHidden = $('#collapse_request_header').is(':hidden');
  //      	hideLoader();
  //       if (isHidden == true ){
  //         $('#request_header_expanded').hide();
  //       }
  //     });
  //   });
  //
  //   $("#coordination_summary").always().click(function(event){
  //     event.preventDefault();
  // 		showLoader();
  //     $('#steps_container').load($('#coordination_summary').attr('href'), function(){
  //       $('#viewSelectedTabs').hide();
  //       $('#collapse_request_link').hide();
  // 	    $('#request_header_expanded').hide();
  // 	    $('#view_request').hide();
  // 			hideLoader();
  //     });
  //   });
  //
  //   $("#activity_summary").always().click(function(event){
  //     event.preventDefault();
  // 		showLoader();
  //     $('#steps_container').load($('#activity_summary').attr('href'), function(){
  //       $('#viewSelectedTabs').hide();
  //       $('#collapse_request_link').hide();
  // 	    $('#request_header_expanded').hide();
  // 	    $('#view_request').hide();
  // 			hideLoader();
  //     });
  //   });


  $('body').on('click', "#done_selection", function () {
    if ($('#selected_values_request_app_ids').find('span').attr('title') == "") {
      $('#select_apps').html('select');
    } else {
      $('#select_apps').html('edit');
    }
  });

  $('body').on('click', "#choose_environment_for_template input[type='submit']", function (e) {
    e.preventDefault();
    createRequestUsingChosenEnv($(this));
  });

  $('body').on('click', "#more_request_notes", function () {
    if ($(this).hasClass('Clicked')) {
      $("div#all_request_notes").show();
      $("#close_request_notes").show();
      $("#more_request_notes, #last_two_notes").hide();
    } else {
      $(this).addClass("Clicked")
      $.get(url_prefix + '/requests/all_notes_for_request', {'id': $(this).attr("request_id") }, function (all_notes) {
        $("#more_request_notes, #last_two_notes").hide();
        $("#close_request_notes").show();
        $("div#all_request_notes").html(all_notes);
      });
    }
  });

  $('body').on('click', "#close_request_notes", function () {
    $("#more_request_notes, #last_two_notes").show();
    $("#close_request_notes, #all_request_notes").hide();
  });

  $('body').on('change', '.toggles input[type="radio"]', toggleReferenceStep);
  $('body').on('click', '.toggles input[type="radio"]', toggleReferenceStep);
  $('body').on("ajax:beforeSend", $("[id*=edit_request]"), function () {
    showLoader(true);
  });
  $('body').on("ajax:complete", $("[id*=edit_request]"), function () {
    hideLoader(true);
  });

  initDeploymentWindow('');
  initDeploymentWindow('popup_');

  loadRequestSteps().done(function () {
    // call init in case we need live updates
    if (window.Stomp && window.ServerMessages) {
      var messages = Request.initServerMessages();
      messages.on('connected', function () {
        messages.pause();
        $.when(updateRetry(updateRequestStatus, 3), updateRetry(updateSteps, 3)).fail(function () {
          alert('Unable to update request info. Request/steps may have outdated status.');
        }).always(function () {
          messages.resume();
        });
      });
    }
  });

});

function loadRequestSteps() {
  var url = $('#request_steps_in_table').attr('data-url');
  var loaderPlaceHolder = $('#steps_loader_placeholder');

  loaderInsideElement(loaderPlaceHolder);

  return $.get(url, function (data) {
//        console.log('requests.js :: loadRequestSteps: arguments = ', arguments);
//        console.log('requests.js :: loadRequestSteps: DONE');
  });
}

function updateRetry(updateMethod, retries) {
  var tryNum = 1,
      def = $.Deferred();

  var doUpdate = function () {
    updateMethod().done(function () {
      def.resolve();
    }).fail(function () {
      ++tryNum;
      if (tryNum > retries) {
        def.reject();
      } else {
        setTimeout(doUpdate, 1000);
      }
    });
  };
  doUpdate();
  return def;
}

var Request = {
  channels: {
    request_update: function (requestId) {
      return '/stomplets/eventable/update/request/id=' + requestId;
    },
    request_destroy: function (requestId) {
      return '/stomplets/eventable/destroy/request/id=' + requestId;
    },
    request_step_update: function (requestId) {
      return '/stomplets/eventable/update/step/format=status_buttons&request_id=' + requestId;
    }
  },
  eventsListener: {},
  messages: null,

  initServerMessages: function () {
    var requestId = $('#request_number').val();
    requestId = parseInt(requestId) - 1000;

    var requestState = $('#aasm_state').val();

    var subscriptions = [
      {
        "channel": this.channels.request_update(requestId),
        "callback": function (data) {
          var request = $.parseJSON(data.body);
          checkRequestStatus(request.aasm_state);
        }
      },
      {
        "channel": this.channels.request_destroy(requestId),
        "callback": redirectToRequestDashboard
      }
    ];
    if ((requestState == 'started') || (requestState == 'problem')) {
      subscriptions.push({
        "channel": this.channels.request_step_update(requestId),
        "callback": function (message) {
          var state_wrapper = get_step_row(message.headers['id']).find('.state_wrapper');
          state_wrapper.closest('form').find('> input').remove();
          state_wrapper.replaceWith(message.body);

          alert_owner_step_ready(message.headers['id']);
        }
      });
    }

    this.messages = new ServerMessages({
      subscriptions: subscriptions
    });
    this.messages.connect();
    return this.messages;
  }
};

function initDeploymentWindow(selector_prefix) {
  bindDeploymentWindowEvents(selector_prefix);

  $('.field #' + selector_prefix + 'request_deployment_window_event_id').livequery(function () {
    var $this = $(this);
    if ($this.data('text') == undefined) { // to prevent undefined label in select box
      $this.val('');
    }
    var form = $this.closest('form');
    $this.select2({
      minimumInputLength: 0,
      width: selector_prefix == '' ? 350 : 200,
      placeholder: "Select Deployment Window",
      initSelection: function (element, callback) {
        callback({id: element.val(), full_text: element.data('text')});
      },
      formatSelection: function (object, container) {
        if (object.start) {
          setPlannedStart(form, new Date(object.start));
        }
        return object.full_text;
      },
      ajax: {
        url: $('#' + selector_prefix + 'deployment_window_event_id_url').val(),
        dataType: 'json',
        quietMillis: 400,
        data: function (term, page) {
          return $.extend(getDeploymentWindowDependsOnParams(form), {
            q: term, //search term,
            page_limit: 25,
            page: page
          });
        },
        results: function (data, page) {
          return data;
        }
      }
    });
    $('#' + selector_prefix + 'request_environment_id').trigger('change');
  });
}

function bindDeploymentWindowEvents(selector_prefix) {
  // this is required to prevent deployment window reset on form initialization
  // since environment select trigger change event during form initialization
  $('body').on('focus', "#request_app_ids, #" + selector_prefix + "request_environment_id", function () {
    $('#' + selector_prefix + 'request_environment_id').addClass('initialized');
  });

  // toggle deployment window select if environment open/closed
  $('body').on('change', "#" + selector_prefix + "request_environment_id", function () {
    $this = $(this);
    var policy = $this.find('option:selected').data('deployment-policy');
    var deployment_window_select = $this.closest('form').find('#' + selector_prefix + 'request_deployment_window_event_id');
    deployment_window_select.closest('.field').toggle(policy == 'closed');
  });

  // Set next available deployment window event
  $('body').on('click', '#' + selector_prefix + 'deployment_window_next', function () {
    var $form = $(this).closest('form');
    var event_el = $form.find('#' + selector_prefix + 'request_deployment_window_event_id');
    var params = $.extend(getDeploymentWindowDependsOnParams($form), { event_id: event_el.val() });
    $.ajax({
      url: $form.find('#' + selector_prefix + 'deployment_window_next_url').val(),
      dataType: 'json',
      data: params,
      success: function (data) {
        if (data) {
          event_el.data('text', data.text);
          event_el.select2('val', data.id);
          setPlannedStart($form, new Date(data.start));
          $('#' + selector_prefix + 'request_deployment_window_event_id').trigger('change');
        }
      }
    });
  });

  $('body').on('change', '#' + selector_prefix + 'request_deployment_window_event_id', function () {
    var $form = $(this).closest('form');
    var event_el = $form.find('#' + selector_prefix + 'request_deployment_window_event_id');
    var params = $.extend(getDeploymentWindowDependsOnParams($form), { event_id: event_el.val() });
    $.ajax({
      url: $form.find('#' + selector_prefix + 'deployment_window_warning_url').val(),
      dataType: 'html',
      data: params,
      success: function (data) {
        if (data) {
          $('#deployment_window_warning').replaceWith(data);
        }
      }
    });
  });

  // Clear deployment window event
  $('body').on('click', '#' + selector_prefix + 'deployment_window_clear', function () {
    $(this).closest('form').find('#' + selector_prefix + 'request_deployment_window_event_id').select2('val', '');
    $('#deployment_window_warning').replaceWith("<div id=\"deployment_window_warning\"></div>");
  });

  // clear deployment window if any of these fields was changed
  $('body').on('change', '#' + selector_prefix + 'request_environment_id', function () {
    var $this = $(this);
    if ($this.is('#' + selector_prefix + 'request_environment_id') && !$this.hasClass('initialized')) {
      return true;
    }
    $this.closest('form').find('#' + selector_prefix + 'request_deployment_window_event_id').select2('val', '');
  });
}

function getDeploymentWindowDependsOnParams(form) {
  var params = {};
  $.each(getDeploymentWindowDependsOnFields(), function () {
    params[this] = requestField(form, this).val();
  });
  return params;
};

function getDeploymentWindowDependsOnFields() {
  return ['environment_id', 'environment_ids', 'scheduled_at_date', 'estimate', 'scheduled_at_hour',
    'scheduled_at_minute', 'scheduled_at_meridian'];
};

function requestField(form, field_name) {
  return form.find("[name='request[" + field_name + "]']");
}

function setPlannedStart(form, date) {
  requestField(form, 'scheduled_at_date').datepicker('setDate', date);
  var hours = date.getHours();
  var minutes = date.getMinutes();

  var ampm = hours >= 12 ? 'PM' : 'AM';
  requestField(form, 'scheduled_at_meridian').val(ampm);

  hours = hours % 12;
  hours = hours ? hours : 12; // the hour '0' should be '12'
  hours = hours < 10 ? '0' + hours : hours;
  requestField(form, 'scheduled_at_hour').val(hours);

  minutes = minutes < 10 ? '0' + minutes : minutes;
  requestField(form, 'scheduled_at_minute').val(minutes);
}

function handleEnvVisibility(url) {
  $.ajax({url: url, dataType: 'script'});
}

function collapseRequestHeader() {
  $("#collapse_request_link").show();
  $("#request_header_expanded").hide();
  $("#request_header_collapse").show();
  $('#collapse_request_header').hide();
  $('#expand_request_header').show();
}

function expandRequestHeader() {
  $("#collapse_request_link").show();
  $("#request_header_expanded").show()
  $("#request_header_collapse").hide();
  $('#expand_request_header').hide();
  $('#collapse_request_header').show();
}

function expandPageContent() {
  ExpandCollapseNotes();
}

function ExpandCollapseNotes() {
  var noteId_Cookie = document.cookie.match('(^|;) ?' + 'noteId' + '=([^;]*)(;|$)');
  if (noteId_Cookie) {
    toggleTextarea('request_notes')
  }
}

function ExpandRequestHeader() {
  var request_id = $('#collapse_request_header').attr('rel');
  cookie_val = $.cookie('requestHeader' + request_id);
  if (cookie_val == 'collapse') {
    collapseRequestHeader();
  } else {
    expandRequestHeader();
  }
}

function CollapseRequestHeader() {
  var request_id = $('#expand_request_header').attr('rel');
  cookie_val = $.cookie('requestHeader' + request_id);
  if (cookie_val == 'expanded') {
    expandRequestHeader();
  } else {
    collapseRequestHeader();
  }
}

function requestHeaderCookie(state) {
  var request_id = $('#expand_request_header').attr('rel');
  $.cookie("requestHeader" + request_id, null);
  $.cookie("requestHeader" + request_id, state);
}

function reloadIfRequestComplete(complete) {
  if ((complete == true) && ($("#reload_page").val() == '1')) {
    var step_ids = unfoldedSteps();
    var url = window.location.href.replace("update_state/start", "").replace(/\?unfolded_steps\=.*/, '') + "?unfolded_steps=" + step_ids;
    window.location = url;
  }
}

function redirectToRequestDashboard() {
  window.location = url_prefix + '/request_dashboard';
}

function load_plan_stages(plan) {
  var plan_stage = plan.parents('div:first').find('select#request_plan_member_attributes_plan_stage_id')
  plan_stage.disable();
  if ((plan.length > 0) && (plan.val() != '')) {
    $.get(url_prefix + '/plans/plan_stage_options', {'plan_id': plan.val()}, function (options) {
      plan_stage.html(options);
    }, "text");
  } else {
    plan_stage.html("<option>Unassigned</option>");
  }
  plan_stage.enable();
}

function setPlanDetails(lc) {
  if (lc != null) {
    $("#setPlanDetails").val(lc['plan_member']["plan_id"]);
    $.get(url_prefix + '/plans/plan_stage_options', {'plan_id': $("#request_plan_member_attributes_plan_id").val()}, function (options) {
      $("#request_plan_member_attributes_plan_stage_id").html(options);
      $("#request_plan_member_attributes_plan_stage_id").val(lc['plan_member']["plan_stage_id"]);
    });
  }
}


function loadTemplateItemProperties(clickedTemplateItem) {
  if (clickedTemplateItem.hasClass('open')) {
    template_item_id = clickedTemplateItem.attr('rel').replace(/template_item_+/g, '')
    $.get(url_prefix + '/requests/template_item_properties', {'request_id': $("#Request_id").val(), 'step_id': $("#Step_id").val(), 'template_item_id': template_item_id}, function (partial) {
      $('#template_item_' + template_item_id).html(partial);
      $('#template_item_' + template_item_id).show();
      clickedTemplateItem.removeClass('open').addClass('close');
    });
  } else {
    clickedTemplateItem.removeClass('close').addClass('open');
    $("#" + clickedTemplateItem.attr('rel')).hide();
  }
}

function ExpandCollapseNotes() {
  var noteId_Cookie = document.cookie.match('(^|;) ?' + 'noteId' + '=([^;]*)(;|$)');
  if (noteId_Cookie) {
    toggleTextarea('request_notes')
  }
}

function updateRequestStatus() {
  var dataURL = url_prefix + '/requests/' + $("#request_number").val() + '/get_status';
  return $.ajax({
    url: dataURL,
    type: 'get',
    dataType: 'text'
  }).done(function (data) {
    checkRequestStatus(data.split('-')[0]);
  });
}

function checkRequestStatus(current_status) {
  if ($("#do_not_reload").val() != '') {
    return;
  }
  var open_steps = unfoldedSteps();
  if (current_status != $("#aasm_state").val()) {
    $("#do_not_reload").val('1');
    var reloadPage = true; // BJB 1/11/11 - only question if design states
    if ((current_status == 'created') || (current_status == 'planned')) {
      reloadPage = confirm("Status of this request has been changed by other user. Click OK to reload page.");
    }
    if (reloadPage) {
      var href = url_prefix + '/requests/' + $('#request_number').val() + '/edit?unfolded_steps=' + open_steps
      window.location = href;
    }
  }
}

function submitStepNotes(clickedBtn) {
  var param = "";
  var stepForm = clickedBtn.parents('form:first');
  if (clickedBtn.attr('step_status') == "running") {
    param += "step_status=running"
  }
  note_val = clickedBtn.parent('div').prevAll('div.textarea:first').find('textarea:first').val();
  params = "note=" + note_val + "&" + param
  path = clickedBtn.attr('path');
  $.ajax({type: 'POST', url: path, data: params,
    success: function (data) {
      clickedBtn.parent('div').prevAll('div#new_note:first').append(data);
      stepForm.find('textarea#step_note').val('');
    }
  });
}

function loadRequestTemplates(clickedLink) {
  closeMultiSelect();
  $.ajax({
    url: clickedLink.attr('rel'),
    type: 'POST',
    data: $('#new_request :input[name != "_method"]').serialize(),
    success: function (partial) {
      $('#request_templates').html(partial);
      $('#new_request input').change();
      if (clickedLink.attr("numeric_pagination")) {
        ajaxifyMyDataPagination();
      }
      else {
        requestTemplateAlphabeticalPagination();
      }
      tablesorterTableHeaderArrowAssignment();
    }
  });
}

function choose_environment_for_template_request() {
  $("body").on('click', "td form.create_request_from_template input[type='submit']", function (e) {
    var form = $(this).parents("form:first");
    e.preventDefault();
    var request_template_id = form.find("#request_template_id").val();
    var plan_id = $("#request_plan_member_attributes_plan_id").val();
    var plan_stage_id = $("#request_plan_member_attributes_plan_stage_id").val();
    closeMultiSelect();
    $.get(url_prefix + "/requests/choose_environment_for_template", {"request_template_id": request_template_id, "plan_id": plan_id, "plan_stage_id": plan_stage_id}, function (html) {
      if (html == "") {
        form.submit();
      } else {
        $.facebox(html);
      }
    });
  });
  return false;
}

function createRequestUsingChosenEnv() {
  var popup_form = $('#choose_environment_for_template');
  var request_template_id = popup_form.find('#request_template_id').val();
  var popup_fields = $('<div class="popup-fields"></div>');
  popup_form.find('.field input, .field select').each(function () {
    if (this.getAttribute('name')) {
      popup_fields.append("<input type='hidden' value='" + this.value + "' name='" + this.getAttribute('name') + "' />");
    }
  });
  var request_template_form = $("#rt_" + request_template_id)
  request_template_form.find('.' + popup_fields.attr('class')).remove();
  request_template_form.append(popup_fields);
  request_template_form.submit();
}


function updateSteps() {
  // Test for Started or Problem state else return
  var target = $("div#steps_container");
  if (formsHaveChanged(target)) return;

  var hidden_divs = $("#hidden_divs_list").val();
  var url = url_prefix + '/requests/' + $('#request_number').val() + '/steps';
  return $.ajax({
    url: url,
    type: "GET",
    data: {hidden_divs_list: hidden_divs},
    dataType: 'script'
  });
}

function gateKeeper() {
  var busy = $('#gatekeeper').val();
  return (busy == "busy")
}

function unfoldedSteps() {
  var ids = [];
  var flag = 0;
  var step_id;

  $('#steps_list tr').each(function () {
    if ($(this).find('td:first a.replace_row:first').parents('tr:first').attr('data-extra-toggle-selector') != undefined) {
      ids.push($(this).find('td:first a.replace_row:first').parents('tr:first').attr('data-extra-toggle-selector').replace(/[^0-9]/g, ''));
      flag = 1;
    }
  });

  if (flag == 0) {
    $('.unfolded').each(function () {
      var new_id_match = this.id.match(/\d+/);
      if (new_id_match) ids.push(new_id_match[0]);
    });
  }
  step_id = ids.join(',');
  return step_id;
}

function formsHaveChanged(container) {
  var returnValue = false;
  container.find('form').each(function () {
    cached_form_data = $(this).data('serialized');
    if (cached_form_data && $(this).serialize() != cached_form_data) returnValue = true;
  });

  return returnValue;
}

function update_request_duration() {
  if ($('#update_request_info').length > 0) {
    $('#update_request_info').trigger('click');
  }
}

function addUnfoldedStepsHiddenField(current_step_id) {
  var form = $("#add_uploads_to_step_form");
  var open_steps = unfoldedSteps();
  if (open_steps != "") {
    open_steps = "," + open_steps;
  }
  var unfolded_steps = current_step_id + open_steps;
  form.append("<input type='hidden' name='unfolded_steps' value='" + unfolded_steps + "'>");
}

function buildScriptList() {
  var script_type = $("#automation_type").val();
  if (script_type == "manual") {
    $("#script_fields").hide();
    $('.step_auto_only').hide();
    $("#script_fields_label").hide();
    //alert("Please choose an automation type");
  } else {
    var url = url_prefix + "/environment/scripts/build_script_list?script_class=" + script_type;
    $.ajax({
      url: url,
      type: 'get',
      beforeSend: function (xhr) {
        //  RF: Not sure why; but this peace of code gets rid of IE7 'Syntex error'; feel free to replace if you find good solution
      }
    }).done(function (data) {
      $("#step_script_id").html(data);
    });
    $("#script_fields").show();
    $("#script_fields_label").show();
  }
}

function displayStepScriptArguments() {
  //var row = $('select#step_script_id').parents('tr:first');
  var row = $('select#step_script_id').parents('div#step_form_holder_tr_div');
  var form = row.find('.step_update_script');
  var script_type = $("#automation_type").val();
  var script_id = $("#step_script_id").val();
  if (script_type != undefined) {
    if (script_id == "") {
      $('#script_section').html("");
    } else {
      var curconts = form.find("#script_hidden_fields input").val();
      form.find("#script_hidden_fields input").val("");
      form.find("#script_hidden_fields input." + script_type + "_hidden").val(script_id);
      form.find('#component_id').val(row.find('#step_component_id').val());
      var curconts2 = row.find('#step_component_id').val();
      var active_owner_div = row.find('select[name="step[owner_id]"]').parent(':visible');
      form.find('#step_owner_id').val(active_owner_div.find('select').val());
      form.find('#step_owner_type').val(active_owner_div.find('input').val());

      var options = {
        data: { script_id: script_id, script_type: script_type },
        beforeSubmit: function () {
          showInnerWaitingWithOverlay();
          $('.step_auto_only').show();
          if (!$("#script_section").is(":visible")) {
            $('#script_heading').trigger('click');
          }
        },
        success: function (html) {
          hideInnerWaitingWithOverlay();
          $('.step_auto_only').show();
          $('#script_section').html(html).prev()[html.match('table') ? 'show' : 'hide']();
        },
        complete: function () {
          adapter_name_values = []
          updateTargetArgumentId();
          if ($(".available_script_arguments").length > 0) {
            var new_options = {
              beforeSubmit: function () {
                $(".available_script_arguments").each(function (index) {
                  argument_id = $(this).val()
                  $("td#argument_" + argument_id).addClass("resource_automation_loader");
                });
              },
              success: function (data) {
                $(".available_script_arguments").each(function (index) {
                  argument_id = $(this).val()
                  $("td#argument_" + argument_id).removeClass("resource_automation_loader");
                  $("td#argument_" + argument_id).html(data[argument_id]);
                  $("td#argument_" + argument_id).append("<span></span>");
                });
              },
              complete: function () {
                updateTargetArgumentId();
                triggerAdapterResourceAutomation();
              },
              error: function (jqXHR, textStatus, errorThrown) {
                $(".resource_automation_loader").each(function () {
                  // This will hide the loader
                  $(this).removeClass("resource_automation_loader");
                  // This will display text N.A indicating the resource automation has failed
                  $(this).html("<input type='text' value='' placeholder='N.A'></input>");
                });
              }
            };
            if (script_type == "RLM Deployment Engine" || script_type == "BMC Remedy 7.6.x") {
              $("form#update_resource_automation_parameters").ajaxSubmit(new_options);
            }
          }

          // Below code is the another way of implementing above functioanlity

          // url = $("form#update_resource_automation_parameters").attr("action");
          // $.ajax({
          //     type: "GET",
          //     data: $("form#update_resource_automation_parameters").serialize(),
          //     dataType: 'json',
          //     url: url,
          //     success: function(data) {
          //       $(".available_script_arguments").each(function(index) {
          //         argument_id = $(this).val()
          //         $("td#argument_"+argument_id).html(data[argument_id]);
          //       });
          //       // $.each($(".available_script_arguments").val(), function(index, value) {
          //       //   argument_id = value
          //       //   $("td#argument_"+argument_id).html(data[value]);
          //       // });
          //     }
          // });
          // return false;
        }
      };
      form.ajaxSubmit(options);
    }
  }
}

function ajaxFileUpload(upload_data) {
  showLoader();
  var uploads_ids = new Array();
  $('input.upload_upload').each(function (index) {
    uploads_ids.push($(this).attr('id'));
  });
  $.ajaxFileUpload({
    url: $("#upload_link").val() + "?" + upload_data,
    secureuri: false,
    fileElementId: uploads_ids,
    dataType: 'POST',
    success: function (data, status) {
      if (typeof(data.error) != 'undefined') {
        if (data.error != '') {
          alert(data.error);
        } else {
          alert(data.msg);
        }
      }
      hideLoader();
    }
  });
  return false;
}

function detectEnvironmentChange(environment_list) {
  // TODO
}

function toggleStepStartAlert(clickedLink) {
  var rel = clickedLink.attr('rel')
  if (rel == "Disable step alerts") {
    $.cookie("turn_on_off", "Enable step alerts");
    $("#toggleStepStartAlert a").attr("title", "Disable step alerts");
    $("#step_owner_message").show();
  } else if (rel == "Enable step alerts") {
    $.cookie("turn_on_off", "Disable step alerts");
    $("#toggleStepStartAlert a").attr("title", "Enable step alerts");
    $("#step_owner_message").hide();
  }
  var title = clickedLink.html();
  clickedLink.html(rel);
  clickedLink.attr('rel', $.trim(title));
}

function checkStepAlertInCookie() {
  if ($.cookie("turn_on_off") != null && $.cookie("turn_on_off") == "Disable step alerts") {
    $("#toggleStepStartAlert").html("<a href='#' class='help' rel='Disable step alerts' onClick='toggleStepStartAlert($(this))'>Enable step alerts</a><span style='color:#000099'>?</span>");
    $("#toggleStepStartAlert a").attr("title", "Enable step alerts");
    $("#step_owner_message").hide();
  } else {
    $("#toggleStepStartAlert").html("<a href='#' class='help' rel='Enable step alerts' onClick='toggleStepStartAlert($(this))'>Disable step alerts</a><span style='color:#000099'>?</span>");
    $("#toggleStepStartAlert a").attr("title", "Disable step alerts");
    $("#step_owner_message").show();
  }
}

function ShowCommonEnvs(options) {
  env_values = [];
  common_env_values = [];
  if (options.replace(/^\s+|\s+$/g, "") != "") {
    $(options).each(function () {
      if (this.text != undefined) {
        env_values.push(this.value);
      }
    });
  }
  common_env_values = find_common(env_values);
  if (common_env_values.length > 0) {
    $.each(common_env_values, function (index, value) {
      $("#request_environment_id option").each(function () {
        if ($.inArray($(this).val(), common_env_values) == -1 && $(this).val().match(/_/) == null) {
          $(this).remove();
        }
      });
    });
    //remove duplicate environments from select list
    removeDuplicates("option");
  }
  ShowCommonEnvGroups();
}

function ShowCommonEnvGroups() {
  env_group_values = [];
  env_group_common_values = [];
  $("#request_environment_id optgroup").each(function () {
    if ($(this).attr("label") != undefined) {
      env_group_values.push($(this).attr("label"));
    }
  });
  env_group_common_values = find_common(env_group_values);
  //remove duplicate environment groups from select list
  if (env_group_common_values.length > 0) {
    $.each(env_group_common_values, function (index, value) {
      $("#request_environment_id optgroup").each(function () {
        if ($.inArray($(this).attr("label"), env_group_common_values) == -1 && $(this).find('option').val().match(/_/) != null) {
          $(this).remove();
        }
      });
    });
    removeDuplicates("optgroup");
  }
}

function removeDuplicates(env_type) {
  var a = new Array();
  $("#request_environment_id").children(env_type).each(function (x) {
    remove = false;
    if (env_type == "optgroup") {
      b = a[x] = $(this).attr("label");
    } else {
      b = a[x] = $(this).val();
    }
    for (i = 0; i < a.length - 1; i++) {
      if (b == a[i]) {
        remove = true;
      }
    }
    if (remove) {
      $(this).remove();
    }
  });
}

function find_common(arr) {
  var len = arr.length,
      out = [],
      counts = {};

  for (var i = 0; i < len; i++) {
    var item = arr[i];
    var count = counts[item];
    counts[item] = counts[item] >= 1 ? counts[item] + 1 : 1;
  }

  for (var item in counts) {
    if (counts[item] > 1)
      out.push(item);
  }

  return out;
}

function appendUnfoldedSteps(current) {
  var open_steps = unfoldedSteps();
  current.attr('href', function () {
    return this.href + '&unfolded_steps=' + open_steps;
  });

  var form = getForm(current);
  saveForm(form, current);
  setFormAction(form, current);
  setFormMethod(form, current);

  form.unbind('submit');

  setFormAjax(form, current);

  form.submit();

  return false;
}

function toggleReferenceStep() {
  var toggles_div = $(this).parents('.toggles:first');
  var selected_input = toggles_div.find('input:checked, option:selected');
  var selected_value = selected_input.attr('value');
  var step_select = $('#referenced_step_id');
  //step_select.attr('disabled', (selected_value == 'environments' || selected_value == 'environment_types') ? 'disabled' : null);
  var show_or_hide = (selected_value == 'environments' || selected_value == 'environment_types') ? 'hidden' : 'visible';
  step_select.parents('.field').attr('style', 'visibility:' + show_or_hide);
}

/*
 * element_selector -- DOM element selector to put loader in
 */
function loaderInsideElement(element_selector) {
  var element = $(element_selector);

  if (element.find('.loading').length > 0) return true;

  element.append('<div class="loading"><img src="' + $.facebox.settings.loadingImage + '"/></div>');
}

function closeMultiSelect(){
    var label = $.find("label:contains('Environments:')");
    if (label.length ) {
        var linkDiv = $.find('#request_link_for_multi_select'),
            multiDiv = $.find('#request_multi_select');
        $(linkDiv).show();
        $(linkDiv).html($('<a>', {href: '#', onclick: 'addRemoveItems(this, "Environment"); return false;', text: 'Add Environments'}));
        $(multiDiv).html('');
    }
}
