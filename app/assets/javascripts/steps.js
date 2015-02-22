////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2014
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(document).ready(function () {

  $('.submit_runtime_phase').live('click', function (e) {
    e.preventDefault();
    $('.submit_runtime_phase').hide();
    $('#runtime_updating').show();
    var request = $.ajax({
      url: $(e.target).prop('href'),
      type: "PUT",
      data: { 'runtime_phase_id': $('select#runtime_phase_id').val() }
    }).done(function () {
      $('#runtime_updating').hide();
      $('.submit_runtime_phase').fadeIn();
    });
  });

  $('body').on('click', 'table#steps_list tr.step td:not(.last,.first,.status)', function () {
    $(document).one('reveal.facebox', function (event) {
      var $active_tab = $('#step_form_tabs .pageSection ul li.selected');
      if ($active_tab.length == 0) {
        $active_tab = $('#step_form_tabs .pageSection ul li:first')
      }
      if ($active_tab.attr('id') != 'st_general') $active_tab.trigger('click');
    });
    $(this).parent().find('td:.last a:.step_editable_link').click();
  });

  $('body').on('click', "#go_to_step", function (event) {
    event.preventDefault();
    var step_id = $("#go_to_step").attr("rel");
    $('html,body').animate({
      scrollTop: $(".step_" + step_id).parent("td").offset().top
    }, 'slow');
  });

  $('body').on('change', "#step_component_id", function () {
    updateAutomationTab($(this).closest('form'), "#step_component_id");
  });

  $('.requests #step_work_task_id, .requests #step_component_id').livequery(function () {
    $(this).loadProperties();
  });

  function updateAutomationTab(form, widgetSelector) {
    var $form = $(form);
    var $widget = $(widgetSelector);
    var stepProtectAutomation = $widget.data('protect-automation') == true;

    if ($widget.val() === undefined || $widget.val() === "") {
      $form.find('#automation_type').val("manual");
      $form.find('#automation_type').attr('disabled', true);
      $form.find("#script_fields").hide();
      $form.find("#script_fields_label").hide();
      // This is handled in steamstep-base.js `loadProperties` method
      $form.find('.step_auto_only').hide();
    } else if ($form.data('executorEntry') || stepProtectAutomation) {
      $form.find('#automation_type').attr('disabled', true);
    } else if (!stepProtectAutomation) {
      $form.find('#automation_type').attr('disabled', false);
    }
  }

  // required to handle hiding of various relevant fields based on corresponding selections. see hideWidgets(level) for more information
  var related_object_selection_level = 1;
  var step_package_level = 2;

  var type_package = "package";
  var type_package_instance = "package_instance";

  $('body').on('change', "#related_object_type_selection", function () {
    var common_url = url_prefix + '/requests/' + $("#request_number").val() + "/steps/"
    if ( $("#procedure_id").val() ){
        common_url = url_prefix + '/environment/metadata/procedures/' + $("#procedure_id").val() + "/"
    }
    var step_related_object_type = $("#step_related_object_type").val();
    var type_param = "?related_object_type=" + step_related_object_type;
    var type_url = common_url + "get_type_inputs" + type_param;
    var form = $('#new_step_form');

    $("#component_or_package_selection").load(type_url, function () {
      $("#component_or_package_selection").css("visibility", "visible");
      hideWidgets(related_object_selection_level);

      if (step_related_object_type === "package") {
        updateAutomationTab(form, "#step_package_id");
        $("#st_content").css("visibility", "visible");
      } else if (step_related_object_type === "component") {
        updateAutomationTab(form, "#step_component_id");
        $("#st_content").css("visibility", "hidden");
      } else {
        updateAutomationTab(form, "");
        $("#st_content").css("visibility", "hidden");
      }

      cleanUpContentTab();
    })
  });

  function cleanUpContentTab() {
      // update content tab through step_controller/load_tab_data
      if($('#st_content').hasClass('selected')) {
          $.get($('#step_form_tabs').attr('data-url'), {'li_id' : "st_content"}, function(data){
              $('#st_content_step_tab_area').html(data);
          }, "html");
      }
  }

  $('body').on('change', "#step_package_id", function () {
    var package_id = $("#step_package_id").val();
    if (package_id && package_id !== "") {
      var step_id = $("#Step_id").val();
      var instance_url = url_prefix + '/requests/' + $("#request_number").val() + "/steps"
      if ( $("#procedure_id").val() ){
          instance_url = url_prefix + '/environment/metadata/procedures/'  +  $("#procedure_id").val()
      }
      instance_url = instance_url + "/get_package_instances?package=" + package_id + "&step_id=" + step_id
      $("#package_instance_selection").load(instance_url, function () {
        $(this).show();
      })
    } else {
      hideWidgets(step_package_level)
    }

    updatePropertiesTabForPackages(type_package, package_id);
    updateContentTabForPackages(type_package, package_id);
    updateAutomationTab($("#step_package_id").closest('form'), "#step_package_id");
  });

  $('body').on('change', "#package_instance_id", function () {
    var package_instance_id = $(this).val();
    var package_id = $("#step_package_id").val();

    if (package_instance_id === "latest" || package_instance_id === "create_new" || package_instance_id === "") {
      updatePropertiesTabForPackages(type_package, package_id);
      updateContentTabForPackages(type_package, package_id);
    } else if (package_instance_id !== "") {
      updatePropertiesTabForPackages(type_package_instance, package_instance_id);
      updateContentTabForPackages(type_package_instance, package_instance_id);
    }
    // DE92033: Request/Step: For Package Instance Type: Select - Automation/Step Action should be selectable
    // changed to step_package_id as updateforall_loaded_properties() function in streamstep-base.js does not handle package_instance_id widget.
    // the package_instance_id handling was removed from updateforall_loaded_properties() to fix another defect.
    updateAutomationTab($("#package_instance_id").closest('form'), "#step_package_id");
  });

  function hideWidgets(level) {
    if (level <= step_package_level) {
      $("#package_instance_selection").val("");
      $("#package_instance_id").val("");
      $("#package_instance_selection").hide();
    }

    if (level === related_object_selection_level) {
      $('#properties_container_new').hide();
      $('#horizontal_rule').hide();
    }
  }

  function updatePropertiesTabForPackages(type, id) {
      if ( $("#procedure_id").val() ){
          return;
      }
    var url_params;
    var step_id = $("#Step_id").val();
    var work_task_id = $("#step_work_task_id").val();
    var container = $("#properties_container").attr('id');

    switch (type) {
      case type_package:
        url_params = {
          step: { package_id: id },
          step_id: step_id,
          work_task_id: work_task_id,
          load_package_properties: 1,
          container: container
        }
        break;
      case type_package_instance:
        url_params = {
          step: { package_instance_id: id },
          step_id: step_id,
          work_task_id: work_task_id,
          load_package_instance_properties: 1,
          container: container
        }
        break;
    }

    $.get($("#step_properties_load_path").val(), url_params);
  }

  function updateContentTabForPackages(type, id) {
    var url_params;
    var step_id = $("#Step_id").val();

    switch (type) {
      case type_package:
        url_params = {
          step: { package_id: id },
          id: step_id,
          step_id: step_id,
          package_or_instance: type_package
        }
        break;
      case type_package_instance:
        url_params = {
          step: { package_instance_id: id },
          id: step_id,
          package_or_instance: type_package_instance
        }
        break;
    }

    var base_url = url_prefix + '/requests/' + $("#request_number").val()  + "/steps/references_for_request";
    if ( $("#procedure_id").val() ){
      base_url = url_prefix + '/environment/metadata/procedures/'  +  $("#procedure_id").val() + "/references_for_procedure";
    }
    $.get( base_url, url_params, function (data) {
      $("#st_content_step_tab_area").html(data);
    });
  }

  $('body').on('change', '#step_completion_state', function () {
    updateStepCompletionState($(this));
  });

  $('.search_for_step').keypress(function (e) {
    if (e.which == 13) {
      e.preventDefault();
      $('#search_for_step').click();
    }
  });

  if ($('#steps_list').find('tbody tr.step').length > 1) {
    $('a#reorder_steps').show();
  } else {
    $('a#reorder_steps').hide();
  }

  $('body').on('click', '.button_action', function (e) {
    e.preventDefault();
    updateStepStatus($(this));
  });

  $('body').on('click', '#bulk_update_submit', function (event) {
    event.preventDefault();
    var button = this;
    var submit_form = false;
    var bulk_update_form = $(this).parents("form:first");
    bulk_update_form.find("select:visible").each(function () {
      var hidden_field_for_select = $("#original_" + $(this).attr("id"))
      if (hidden_field_for_select.length > 0) {
        if ($(this).val() != hidden_field_for_select.val()) {
          submit_form = true
        }
      }
    });
    if ($("#original_assignment").length > 0) {
      var owner_type = bulk_update_form.find("select:visible[id='step_owner_type']");
      var owner_id = bulk_update_form.find("select:visible[id='step_owner_id']");
      var modified_assignment = owner_type.val() + '_' + owner_id.val();
      if (modified_assignment == $("#original_assignment").val()) {
        submit_form = false;
      } else {
        submit_form = true;
      }
    }
    if ($("#original_step_should_execute").length > 0) {
      if (submit_form && bulk_update_form.find("#step_should_execute").val() == "") {
        alert("Step status cannot be left blank");
        return false;
      }
    }
    if (submit_form) {
      // Do not allow user to save step without Owner
      if ($("#original_assignment").length > 0) {
        if ((modified_assignment != $("#original_assignment").val()) && (owner_type.val() == "")) {
          alert("Step Owner cannot be left blank.");
          return false;
        }
      }
      var overlayPopup = true;
      showLoader(overlayPopup);
      $(button).disable();

      // Some select list values are changed so submit form
      $.ajax({
        url: bulk_update_form.attr('action'),
        type: 'PUT',
        dataType: 'script',
        data: bulk_update_form.serialize(),
        success: function (data) {
        },
        complete: function () {
          hideLoader(overlayPopup);
          $(button).enable();
        }
      });
    } else {
      // Nothing changed so just close facebox without submitting form
      $.facebox.close();
    }
  });

  $('#check_visible').hide();

  $('body').on('click', "#step_version_tag_id", function (event) {
    showArtifactPath($(this));
  });

  //step time calculation
  $('body').on('change', '#step_start_by_meridian', function (event) {
    estimate_time_on_start_and_complete_dates();
  });
  $('body').on('change', '#step_start_by_minute', function (event) {
    estimate_time_on_start_and_complete_dates();
  });
  $('body').on('change', '#step_start_by_hour', function (event) {
    estimate_time_on_start_and_complete_dates();
  });
  $('body').on('change', '#step_start_by_date', function (event) {
    restrictStepEndDateSelection();
    estimate_time_on_start_and_complete_dates();
  });
  $('body').on('change', '#step_complete_by_meridian', function (event) {
    estimate_time_on_start_and_complete_dates();
  });
  $('body').on('change', '#step_complete_by_minute', function (event) {
    estimate_time_on_start_and_complete_dates();
  });
  $('body').on('change', '#step_complete_by_hour', function (event) {
    estimate_time_on_start_and_complete_dates();
  });
  $('body').on('change', '#step_complete_by_date', function (event) {
    estimate_time_on_start_and_complete_dates();
  });

  $('body').on('change', '.step_form select#step_owner_id, .procedure_step_form select#step_owner_id', function (event) {
    $('.step_form #step_owner_type, .procedure_step_form #step_owner_type').val($(this).find('option:selected').parents("optgroup:first").attr('owner_type'));
  });

  restrictStepEndDateSelection();

  $("#parameter_type").livequery("change", function () {
    showInnerWaitingWithOverlay();
    render_output_step_view($(this).val());
  });
  $('body').on('keydown', "#step_estimate_hours, #step_estimate_minutes", function (event) {
    reset_estimate_start_and_complete_dates();
  });
});

function updateStepStatus(step) {
  var status_form = step.parents("form:first");
  var step_status = step.attr('name');
  var hidden_divs_list = $("#hidden_divs_list").val();
  var open_steps = unfoldedSteps();

  status_form.append('<input type="hidden" id="' + step_status + '.x" value="true" name="' + step_status + '.x" />')
  status_form.append('<input type="hidden" id="' + hidden_divs_list + '" value="' + hidden_divs_list + '" name="hidden_divs_list" />')
  status_form.append('<input type="hidden" id="unfolded_steps" value="' + open_steps + '" name="unfolded_steps" />')

  var property_field_new = $("#update_step_status").find("input.step_property_value:first").val();
  var property_values = "#update_step_status input.step_property_value";
  var server_property_values = "#update_step_status input.server_property_value"

  var property_names = "div#property_results div.property_field input";
  $(property_names).each(function () {
    var pn = $(this);
    $(property_values).each(function () {
      if ($(this).attr("name") == pn.attr("name")) {
        status_form.append('<input type="hidden" value="' + $(this).val() + '" name="' + $(this).attr("name") + '" />');
      }
    });
  });
  $(server_property_values).each(function () {
    status_form.append('<input type="hidden" value="' + $(this).val() + '" name="' + $(this).attr("name") + '" />');
  });

  status_form.append('<input type="hidden" id="' + step_status + '.x" value="true" name="' + step_status + '.x" />')
  $.ajax({
    url: status_form.attr('action'),
    type: 'POST',
    dataType: 'script',
    data: step.parents("form:first").serialize(),
    success: function (data) {
    }
  });
  return false;
}

function submitFixNote() {
  var hidden_divs = $("#hidden_divs_list").val();
  $('form.add_step_category').livequery(function () {
    $(this).ajaxForm({
      type: 'POST',
      dataType: 'script',
      data: ( {
        hidden_divs_list: hidden_divs
      }),
      success: function (data) {
        $('div#facebox').hide();
      }
    });
  });
  return false;
}

function change_step_status(link) {
  link.hide().spin();
  var form = link.parents('form:first');
  checkbox = form.find("input[type='checkbox']");
  select_checkbox = checkbox.parents("tr:first").find("td:first > input:checkbox");
  if (link.html() == "ON") {
    link.parents('tr').addClass('step_off');
    link.html("OFF");
    checkbox.removeAttr('checked');
    select_checkbox.addClass("OFF");
    select_checkbox.removeClass("ON");
    link.addClass("OFF")
    link.removeClass("ON")
  } else {
    link.parents('tr').removeClass('step_off');
    link.html("ON");
    checkbox.attr('checked', 'checked');
    select_checkbox.addClass("ON");
    select_checkbox.removeClass("OFF");
    link.addClass("ON")
    link.removeClass("OFF")
  }
  $('div.request_buttons').find('a, input').attr('disabled', 'disabled');
  form.ajaxSubmit(function () {
    link.next().remove();
    link.show();
    if ($(':input.step_should_execute').length) {
      if (anyStepsToExecute()) {
        $(".anyStepsCheckedtrue").show();
        $(".anyStepsCheckedfalse").hide();
      } else {
        $(".anyStepsCheckedfalse").show();
        $(".anyStepsCheckedtrue").hide();
      }
    }
    update_request_duration();
    $('div.request_buttons').find('a, input').removeAttr('disabled')
  });
}

// function controlling the run now button
function change_run_now_status(link) {
  link.hide().spin();
  var form = link.parents('form:first');
  checkbox = form.find("input[type='checkbox']");
  select_checkbox = checkbox.parents("tr:first").find("td:first > input:checkbox");
  if (checkbox.checked == true) {
    checkbox.removeAttr('checked');
    select_checkbox.addClass("REP");
    select_checkbox.removeClass("RUN");
  } else {
    checkbox.attr('checked', 'checked');
    select_checkbox.addClass("RUN");
    select_checkbox.removeClass("REP");
  }
  $('div.request_buttons').find('a, input').attr('disabled', 'disabled');
  form.ajaxSubmit(function () {
    link.next().remove();
    link.show();
    if ($(':input.step_should_execute').length) {
      if (anyStepsToExecute()) {
        $(".anyStepsCheckedfalse").show();
        $(".anyStepsCheckedtrue").hide();
      } else {
        $(".anyStepsCheckedtrue").show();
        $(".anyStepsCheckedfalse").hide();
      }
    }
    update_request_duration();
    $('div.request_buttons').find('a, input').removeAttr('disabled')
  });
}

function anyStepsToExecute() {
  var anyStepsChecked = false;
  $("#steps_list").find('.step_should_execute').each(function () {
    if (this.value == "1") {
      anyStepsChecked = true;
    }
  });
  return anyStepsChecked
}

function OLD_change_step_status(link) {
  link.hide().spin();
  var form = link.parents('form:first');
  checkbox = form.find("input[type='checkbox']");
  select_checkbox = checkbox.parents("tr:first").find("td:first > input:checkbox");
  if (link.html() == "ON") {
    link.html("OFF");
    checkbox.val("0")
    select_checkbox.addClass("OFF");
    select_checkbox.removeClass("ON");
  } else {
    link.html("ON");
    checkbox.val("1");
    select_checkbox.addClass("ON");
    select_checkbox.removeClass("OFF");
  }
  $('div.request_buttons').find('a, input').attr('disabled', 'disabled');
  form.ajaxSubmit(function () {
    link.next().remove();
    link.show();
    if ($(':input.step_should_execute').length) {
      anyStepsChecked = false;
      $("#steps_list").find('.step_should_execute').each(function (index) {
        if (checkbox.attr('checked') == true) {
          anyStepsChecked = true;
        }
      });
      if (anyStepsChecked == false) {
        $(".anyStepsCheckedfalse").show();
        $(".anyStepsCheckedtrue").hide();
      } else {
        $(".anyStepsCheckedtrue").show();
        $(".anyStepsCheckedfalse").hide();
      }
    }
    update_request_duration();
    $('div.request_buttons').find('a, input').removeAttr('disabled')
  });
}

function checkSteps(selection) {
  var td = $("td.step_position");
  switch (selection) {
    case 1 :
      // select all steps
      td.find("input[type='checkbox']").attr("checked", true);
      break;
    case 2 :
      // remove selection of all steps
      td.find("input[type='checkbox']").removeAttr("checked");
      break;
    case 3 :
      // select ON steps
      td.find("input[type='checkbox']").removeAttr("checked");
      td.find(".ON").attr("checked", "checked");
      break;
    case 4 :
      // select OFF steps
      td.find("input[type='checkbox']").removeAttr("checked");
      td.find(".OFF").attr("checked", "checked");
      break;
    case 5 :
      // select visible steps
      $("td:visible.step_position").find("input[type='checkbox']").attr("checked", true);
      break;
  }
}

function bulkUpdate(action, confirm_msg, no_facebox) {
  var steps = $(".step_position").find("input[type='checkbox']").map(function () {
    if ($(this).is(':checked'))
      return $(this)
  });
  if (steps.length <= 0) {
    switch (action) {
      case "delete":
        var no_facebox = true;
        var msg = "Please select steps to delete";
        break;
      case "modify_assignment":
        var msg = "Please select steps whose assignment needs to be modified";
        break;
      case "modify_app_component":
        var msg = "Please select steps whose app/component needs to be modified";
        break;
      case "modify_task_phase":
        var msg = "Please select steps whose task/phase needs to be modified";
        break;
      case "modify_should_execute":
        var msg = "Please select steps whose status needs to be modified";
        break;
    }
    alert(msg);
  } else {

    // Collecting Step IDS
    var step_ids = [];
    steps.each(function () {
      step_ids.push($(this).attr("id").replace(/[^0-9]/g, ''));
    });

    // Show Facebox if applied action IS NOT delete
    if (no_facebox == undefined) {
      $.facebox(function () {
        $.get(url_prefix + "/requests/" + $("#request_number").val() + "/steps/bulk_update", {
          "operation": action,
          "step_ids[]": step_ids
        }, function (data) {
          $.facebox(data);
        });
      });
    } else {
      if (confirm_msg == undefined) {
        var run_action = true;
      } else {
        var run_action = confirm(confirm_msg);
      }
      if (run_action) {
        $.ajax({
          url: url_prefix + "/requests/" + $("#request_number").val() + "/steps/bulk_update",
          type: action == "delete" ? "DELETE" : "PUT",
          data: {
            "step_ids[]": step_ids,
            "apply_action": action
          },
          dataType: 'script'
        });
      }
    }
  }
}

function display_owner_id_list(owner_type_list) {
  var form = owner_type_list.parents("form:first");
  owner_type_list.find("option").each(function () {
    if ($(this).html() != 'Select') {
      form.find("." + $(this).val()).hide().attr("disabled", "disabled");
      form.find(".default_select").hide();
    }
  });
  if (owner_type_list.val() != '') {
    form.find("." + owner_type_list.val()).removeAttr("disabled").show();
    form.find('.default_select_span').remove();
  } else {
    var lable = $('select#step_owner_id').next('span:first').html();
    form.find(".default_select").show();
    form.find(".default_select").after("<span class = 'default_select_span'> " + lable + "</span>");
  }
}

function updateComponentList(app_select) {
  var form = app_select.parents("form:first");
  var request_id = form.find('input[name = request_id]')
  $.ajax({
    url: app_select.attr("rel"),
    type: "GET",
    data: {
      "step[app_id]": app_select.val(),
      "request_id": request_id.val()
    },
    dataType: "html",
    success: function (selectOptions) {
      form.find("#" + app_select.attr("update")).html(selectOptions);
    }
  });
}

// Searches steps locally - client side scripting
function localSearch(link) {
  checkSteps(2);
  var query = (link.parents("div:first").find("input[name='query']").val()).toLowerCase();
  if (query == "") {
    $('#check_visible').hide();
    $('#check_all').show();
    searchResponse("Please provide keyword to search")
    showSteps();
  } else {
    $('#check_visible').show();
    $('#check_all').hide();
    var pattern = new RegExp(query, "m");
    var rows = $("#steps_container").find('table#steps_list thead tr, table#steps_list tbody tr');
    $('table#steps_list thead tr:first').show();
    rows.hide();
    $('table#steps_list thead tr:first').show();
    if ($("table#steps_list tbody tr td div a ").attr("class") == "edit") {
      $("table#steps_list tbody tr:last").show();
    }
    $('.step_links_wrapper').css('border', '2px #09B200 solid');
    var step_ids = [];
    rows.each(function (idx) {
      var text = $(this).text();
      if ($(this).find('#step_name').length > 0) {
        var input_fields = [];
        $(this).find('input').each(function () {
          input_fields.push($(this).val())
        });
        text += input_fields
      }
      if (pattern.test((text).toLowerCase())) {
        $(this).show();
        step_ids.push($(this).attr("id"));
        // Display parent step when display child steps in search results
        if ($(this).attr("data-parent-id")) {
          $("#step_" + $(this).attr("data-parent-id")).show();
        }
      }
    });
    if (step_ids.length == 0) {
      searchResponse("No match found !")
    } else {
      searchResponse("");
    }
  }
}

function searchResponse(message) {
  if ($("#step_search").find("span").length == 0) {
    $("#step_search").append("<span></span>")
  }
  $("#step_search span").html(message);
}

// Sends request to server to search steps
function searchSteps(link) {
  checkSteps(2);
  var query = link.parents("div:first").find("input[name='query']").val();
  if (query == "") {
    showSteps();
  } else {
    $.getJSON(url_prefix + "/requests/" + $("#request_number").val() + "/steps/search?format=json", {
      "query": query
    }, function (step_ids) {
      showSteps(step_ids);
    });
  }
}

function showSteps(step_ids) {
  var steps_table = $("#steps_list tbody");
  if (step_ids == undefined) {
    steps_table.find("tr:not(#first_step_row_tbody)").show();
  } else {
    steps_table.find("tr").hide();
    $.each(step_ids, function (index, step_id) {
      var step = steps_table.find("tr[id*='" + step_id + "']");
      step.show();
      if (step.html() != null) {
        var step_id = step.attr("class").replace(/[^0-9]/g, '');
        $("#step_" + step_id).show();
      }
    });
  }
}

function clearQuery(link) {
  link.parents("div:first").find("input[name='query']").val('');
  searchResponse("");
  showSteps();
  $('.step_links_wrapper').css('border', '2px #6D7B8D solid');
  $("#steps_container").find('table#steps_list thead tr, table#steps_list tbody tr:not(#first_step_row_tbody)').show();
  $('#check_visible').hide();
  $('#check_all').show();
}

function retainTwiddleStates() {
  $(getCookieList('step-toggles')).each(function (id) {
    openTwiddle(this);
  });
}

function openTwiddle(cookie) {
  cookie = cookie.split("_id_");
  var step_id = cookie[0].split("step_")[0];
  var step_tr = $("#steps_list > tbody > tr:visible[id*='" + step_id + "']");
  var heading_id = cookie[1];
  var heading = step_tr.find("#" + heading_id);
  if (heading) {
    heading.toggleClass('unfolded');
    $("#" + heading_id.replace("heading", "section")).show();
  }
}

function AddLabelForSelectLists(bulk_update_table) {
  switch (bulk_update_table) {
    case "modify_assignment":
      AddLabel('modify_assignment', 'owner_type', 'owner_type_span');
      AddLabel('modify_assignment', 'owner_name', 'user_span');
      AddLabel('modify_assignment', 'owner_name', 'group_span');
      break;
    case "modify_app_component":
      AddLabel('modify_app_component', 'app_name', 'app_span');
      AddLabel('modify_app_component', 'comp_name', 'comp_span');
      break;
    case "modify_task_phase":
      AddLabel('modify_task_phase', 'task_name', 'task_span');
      AddLabel('modify_task_phase', 'phase_name', 'phase_span');
      break;
    case "modify_should_execute":
      AddLabel('modify_should_execute', 'step_status', 'step_status_span');
      break;
  }
}

function AddLabel(div_class, td_class, elem_span) {
  elem = []
  parent_div = $('.' + div_class)
  table_trs = parent_div.find('table tbody tr');
  table_trs.each(function () {
    elem.push($(this).find('td.' + td_class).html());
  })
  if (uniqArray(elem).length > 1) {
    $('.' + elem_span).html("Varies");
  }
}

function DisplayAssignmentForSameOwnerType(div_class) {
  //  Check if selected steps has same owner_type for bulk Modify Assignment
  //  if yes, display select list of that owner_type
  elem = []
  parent_div = $('.' + div_class)
  form = parent_div.parents('form:first')
  table_trs = parent_div.find('table tbody tr');
  table_trs.each(function () {
    elem.push($(this).find('td.owner_type').html());
  })
  if (uniqArray(elem).length == 1) {
    form.find('select#step_owner_type').val(uniqArray(elem))
    form.find('.' + uniqArray(elem)).show().removeAttr('disabled');
    form.find('.default_select').hide();
  }
}


function validateDateTime(form) {
  if ((operationsTicketPresent(form))) {
    var pattern = /^(?=\d)(?:(?!(?:1582(?:\.|-|\/)10(?:\.|-|\/)(?:0?[5-9]|1[0-4]))|(?:1752(?:\.|-|\/)0?9(?:\.|-|\/)(?:0?[3-9]|1[0-3])))(?=(?:(?!000[04]|(?:(?:1[^0-6]|[2468][^048]|[3579][^26])00))(?:(?:\d\d)(?:[02468][048]|[13579][26]))\D0?2\D29)|(?:\d{4}\D(?!(?:0?[2469]|11)\D31)(?!0?2(?:\.|-|\/)(?:29|30))))(\d{4})([-\/.])(0?\d|1[012])\2((?!00)[012]?\d|3[01])(?:$|(?=\x20\d)\x20))?((?:(?:0?[1-9]|1[012])(?::[0-5]\d){0,2}(?:\x20[aApP][mM]))|(?:[01]\d|2[0-3])(?::[0-5]\d){1,2})?$/;
    var invalid_fields = new Array();
    form.find("#integration_data").find("input[id*='date']").each(function () {
      if ($(this).val().length > 0) {
        if (!$(this).val().match(pattern)) {
          invalid_fields.push($(this).attr("id"));
        } else {
          form.find("#" + $(this).attr("id")).parents(".property_field:last").find("span").remove();
        }
      }
    });
    if (invalid_fields.length > 0) {
      $.each(invalid_fields, function (index, dom_id) {
        if (form.find("#" + dom_id).parents(".property_field:last").find("span").length > 0) {
          form.find("#" + dom_id).parents(".property_field:last").find("span").remove();
        }
        form.find("#" + dom_id).parents(".property_field:last").find("div.err_msg").remove();
        form.find("#" + dom_id).parents(".property_field:last").append("<div class='clear err_msg' style='padding-left:132px'><span>Format: YYYY-MM-DD HH:MM:SS</span></div>");
      });
      hideLoader();
      return false;
    } else {
      return true;
    }
  } else {
    return true;
  }
}

function updateStepCompletionState(step) {
  if (step.attr("step_id").length > 0) {
    $.ajax({
      type: "PUT",
      data: {
        "step[completion_state]": step.val()
      },
      url: url_prefix + "/requests/" + $("#request_number").val() + "/steps/" + step.attr("step_id") + "/update_completion_state",
      beforeSend: function () {
        showLoader();
      },
      error: function () {
        hideLoader();
        alert("Request Failed");
      },
      success: function (sys_id) {
        hideLoader();
      }
    });
  }
}

// This function is not used now, instead a new function has been created with the name submitStepFormFromFacebox()
// for showing and submiting the step form on facebox

function submitStepForm(clickedBtn) {
  showLoader();
  $("#step_action_links").removeClass("dn");
  var stepForm = clickedBtn.parents('form:first');
  if ($(stepForm).html() == null) {
    var stepForm = clickedBtn.parents('tr:first').find('form:first');
  }
  var asset_upload = $('input.asset_upload').val();
  if (clickedBtn.val() == 'Save Step' || clickedBtn.val() == 'Update') {
    var add_step = '0';
  } else {
    var add_step = '1';
  }
  step_app_id = $('#step_component_id').find('option:selected').attr('app_id');
  installed_component_id = $('#step_component_id').find('option:selected').attr('installed_component_id');
  hiddenFields = '<input type="hidden" name="only_save" value="' + add_step + '" />';
  hiddenFields += '<input type="hidden" name="unfolded_steps" value="" />';
  hiddenFields += '<input type="hidden" name="hidden_divs_list" value="" />';
  if (step_app_id != undefined) {
    hiddenFields += '<input type="hidden" name="step[app_id]" value="' + step_app_id + '" />';
  }
  if (installed_component_id != undefined) {
    hiddenFields += '<input type="hidden" name="step[installed_component_id]" value="' + installed_component_id + '" />';
  }

  stepForm.append(hiddenFields);
  var params = {};
  params = $(stepForm).serialize();
  var procedure_step_id = $(stepForm).hasClass('procedure_form') ? $(stepForm).find('#step_parent_id').attr('value') : '';
  $.ajax({
    url: $(stepForm).attr("action") + "?" + "&ajax_request=true",
    type: "POST",
    data: params,
    success: function (data) {
      try {
        var conds = $("<div>").html(data).find('span.dummy_span').length > 0
      } catch (e) {
        var conds = true
      }
      if (conds) {
        if (params.indexOf("method=put") == -1) {
          var last_table_row = $(stepForm).hasClass('procedure_form') ? $('#steps_list').find('tr.editable.parent_' + procedure_step_id + '.procedure_step:last') : $('#steps_list > tbody > tr:not(.container):last');
          if ($('#steps_list').find('tr.editable:last').size() == 0 && !$(stepForm).hasClass('procedure_form')) {
            last_table_row = $('#steps_list').find('tr#first_step_row_tbody');
          }

          last_table_row = ($(last_table_row).html() == null && $(stepForm).hasClass('procedure_form') ) ? $('#steps_list').find('tr#step_' + procedure_step_id) : last_table_row

          $(last_table_row).after(data);
          var current_table_row = $(stepForm).hasClass('procedure_form') ? $('#steps_list').find('tr.editable.parent_' + procedure_step_id + '.procedure_step:last') : $('#steps_list').find('tr.editable:last');

          current_table_row = ($(current_table_row).html() == null && $(stepForm).hasClass('procedure_form') ) ? $('#steps_list').find('tr#step_' + procedure_step_id) : current_table_row

          if ($(last_table_row).attr('class').indexOf('even_step_phase') != -1) {
            $(current_table_row).addClass("odd_step_phase")
          } else {
            $(current_table_row).addClass("even_step_phase")
          }
          $(last_table_row).after($(current_table_row));
          $(stepForm).hasClass('procedure_form') ? $('#steps_list').find('tr.editable.parent_' + procedure_step_id + '.procedure_step:last').nextAll('table').remove() : $('#steps_list').find('tr.editable:last').nextAll('table').remove()
        }

        showHideReorderStepsLinks();
        update_request_duration();

        if (clickedBtn.val() == 'Update') {
          stepForm.find('.options').find('a').trigger('click');
          clickedBtn.parents('tr:first').prev().remove();
        } else {
          stepForm.find('.options').find('a').trigger('click');
        }
        if (add_step == '1') {
          if (stepForm.find('#step_different_level_from_previous').is(':checked')) {
            parallel = '';
          } else {
            parallel = true;
          }
          if ($(stepForm).hasClass('procedure_form')) {
            var procedure_row = $('#steps_list').find('tr.procedure#step_' + procedure_step_id)
            var last_step_row = procedure_row.nextAll("tr[data-parent-id=" + procedure_step_id + "]:last");
            if (last_step_row.length == 0)
              last_step_row = procedure_row;
            var klass = '';
            if ($(last_step_row).attr('class').indexOf('even_step_phase') != -1) {
              klass = 'odd_step_phase';
            } else {
              klass = 'even_step_phase';
            }
            last_step_row.after("<tr class=\"procedure_step " + klass + "\"> </tr>");
            last_step_row.next().load($("#new_procedure_path_url").val() + '?parallel=' + parallel + '&procedure_add_new=' + true, function () {
              $('#Wrapper').scrollTop($('table#steps_list tr.step:last').position().top + 100);
            });
            last_step_row.removeClass('last');
            last_step_row.next().addClass('last');
          } else {
            $('tr.container').load(url_prefix + '/requests/' + $("#request_number").val() + '/steps/new?parallel=' + parallel, function () {
              $('#Wrapper').scrollTop($('table#steps_list tr.step:last').position().top + 100);
            });
          }
          return false;
        } else {
          var position = $('table#steps_list tr.step:last').position().top - $('table#steps_list tr.step:last').offset().top
          $('#Wrapper').scrollTop(position - 200);
        }
        hideLoader();
      }
    }
  });
}
function submitStepFormFromFacebox(clickedBtn) {
  showInnerWaitingWithOverlay();
  $("#step_action_links").removeClass("dn");
  var stepForm = $('form#new_step_form');
  if ($(stepForm).html() == null) {
    var stepForm = clickedBtn.parents('tr:first').find('form:first');
  }
  if (clickedBtn.val() == 'Save Step' || clickedBtn.val() == 'Update' || clickedBtn.val() == 'Add Step & Close') {
    var add_step = '0';
  } else {
    var add_step = '1';
  }
  step_app_id = $('#step_component_id').find('option:selected').attr('app_id');
  installed_component_id = $('#step_component_id').find('option:selected').attr('installed_component_id');
  package_id = $('#step_package_id').find('option:selected').attr('package_id');
  package_instance = $('#package_instance_id').find('option:selected').val();
  var $related_object_type = $('#step_related_object_type');
  var related_object_type_value = $related_object_type.val();

  hiddenFields = '<input type="hidden" name="only_save" value="' + add_step + '" />';
  hiddenFields += '<input type="hidden" name="unfolded_steps" value="" />';
  hiddenFields += '<input type="hidden" name="hidden_divs_list" value="" />';
  hiddenFields += '<input type="hidden" name="step[related_object_type]" value="' + related_object_type_value + '" />';

  if (step_app_id != undefined) {
    hiddenFields += '<input type="hidden" name="step[app_id]" value="' + step_app_id + '" />';
  }

  if (installed_component_id != undefined) {
    hiddenFields += '<input type="hidden" name="step[installed_component_id]" value="' + installed_component_id + '" />';
  }

  if ($related_object_type.length > 0 && related_object_type_value !== "component") {
      hiddenFields += '<input type="hidden" name="step[component_id]" value="" />';
  }

  package_id = package_id === undefined ? '' : package_id;
  hiddenFields += '<input type="hidden" name="step[package_id]" value="' + package_id + '" />';
  var latest_package_instance = false;
  var create_new_package_instance = false;
  var package_instance_id = "";

  switch (package_instance) {
    case "latest":
      latest_package_instance = true;
      break;
    case "create_new":
      create_new_package_instance = true;
      break;
    default:
      package_instance_id = package_instance;
      break;
  }

  hiddenFields += '<input type="hidden" name="step[package_instance_id]" value="' + package_instance_id + '" />';
  hiddenFields += '<input type="hidden" name="step[latest_package_instance]" value="' + latest_package_instance + '" />';
  hiddenFields += '<input type="hidden" name="step[create_new_package_instance]" value="' + create_new_package_instance + '"/>';

  if ($.browser.msie) {
    hiddenFields += '<input type="hidden" name="internet_explorer_fix" value="true" />';
  }
  stepForm.append(hiddenFields);
  /*Merge form data with selected tree node data, if tree is present in the form*/
  var addPostdata = {ajax_request: 'true'};
  $(".tree_renderer").each(function () {
    var dt = $(this).dynatree("getTree").serializeArray();
    $.each(dt, function () {
      if (addPostdata[this.name] == undefined) {
        addPostdata[this.name] = encodeURIComponent(this.value);
      } else {
        addPostdata[this.name] = addPostdata[this.name].concat(",").concat(encodeURIComponent(this.value));
      }

    });
  });
  clearDuplicatedArgumentValues();
  stepForm.ajaxSubmit({
    type: "POST",
    data: addPostdata,
    success: (clickedBtn.val() == 'Save Step') ? onSuccessUpdateAllStep : ((add_step == '1') ? onSuccessOfStepSubmissionContinue : onSuccessOfStepSubmissionClose)
  });
  showHideReorderStepsLinks();
}

/*
  This is method delete hidden fields for checked checkboxes(before updating step)
  in resource automation tables on current pages.
  Checkboxes and hidden fields have the same name. Used for tables pagination.
  Can be removed if pagination will be changed(removed)
*/
function clearDuplicatedArgumentValues(){
  checked = $("#st_automation_step_tab_area").find('input:checkbox:checked');
  $.each(checked, function()
  {
    table_argument_id = $(this).attr("id").split('_')[1];
    value = $(this).val();
    $('#argument_' + table_argument_id + '_' + value.replace('.','\\.')).remove();
  });
}

function onSuccessUpdateAllStep(data, status, xhr) {
  /*RF: followting fix applied for internet explorer issues*/
  if (data.match("error_messages_for_step") == null) {
    if (data.match("errorExplanation") == null) {
      $('#steps_container').html(data);
      $.facebox.close();
    } else {
      $("#error_messages_for_step").html(data);
    }
  }
  hideInnerWaitingWithOverlay();
}
function onSuccessOfStepSubmissionContinue(data, status, xhr) {
  /*RF: followting fix applied for internet explorer issues*/
  if (data.match("error_messages_for_step") == null) {
    if (data.match("errorExplanation") == null) {
      onSuccessOfStepSubmission(data, status, xhr)
      if ($('form#new_step_form').find('#step_different_level_from_previous').is(':checked')) {
        parallel = '';
      } else {
        parallel = true;
      }

      if ($('form#new_step_form').hasClass('procedure_form')) {
        $('#facebox .content').load($("#new_procedure_path_url").val() + '?parallel=' + parallel + '&procedure_add_new=' + true, function () {
          hideInnerWaitingWithOverlay();
        });
      } else if ($('form#new_step_form').hasClass('new_procedure_step')) {
        href = $('.add_new_procedure_step').attr("href")
        $('#facebox .content').load(href + parallel, function () {
          hideInnerWaitingWithOverlay();
        });
      }
      else {
        $('#facebox .content').load(url_prefix + '/requests/' + $("#request_number").val() + '/steps/new?parallel=' + parallel, function () {
          hideInnerWaitingWithOverlay();
        });
      }
      return false;
    } else {
      $("#error_messages_for_step").html(data);
    }
  }
  hideInnerWaitingWithOverlay();
}

function onSuccessOfStepSubmissionClose(data, status, xhr) {
  /*RF: followting fix applied for internet explorer issues*/
  if (data.match("error_messages_for_step") == null) {
    if (data.match("errorExplanation") == null) {
      onSuccessOfStepSubmission(data, status, xhr)
      $.facebox.close();
    } else {
      $("#error_messages_for_step").html(data);
    }
  }
  hideInnerWaitingWithOverlay();
}

function onSuccessOfStepSubmission(data, status, xhr) {
  var stepForm = $('form#new_step_form');
  var procedure_step_id = stepForm.hasClass('procedure_form') ? $('form#new_step_form').find('#step_parent_id').attr('value') : '';
  if (stepForm.serialize().indexOf("method=put") == -1) {
    var last_table_row = stepForm.hasClass('procedure_form') ? $('#steps_list').find('tr.listable.parent_' + procedure_step_id + '.procedure_step:last') : $('#steps_list > tbody > tr:not(.container):last');
    if ($('#steps_list').find('tr.listable:last').size() == 0 && !stepForm.hasClass('procedure_form')) {
      last_table_row = $('#steps_list').find('tr#first_step_row_tbody');
    }

    last_table_row = ( $(last_table_row).html() == null && stepForm.hasClass('procedure_form') ) ? $('#steps_list').find('tr#step_' + procedure_step_id) : last_table_row

    $(last_table_row).after(data);
    var current_table_row = stepForm.hasClass('procedure_form') ? $('#steps_list').find('tr.listable.parent_' + procedure_step_id + '.procedure_step:last') : $('#steps_list').find('tr.listable:last');
    current_table_row = ( $(current_table_row).html() == null && stepForm.hasClass('procedure_form') ) ? $('#steps_list').find('tr#step_' + procedure_step_id) : current_table_row

    if ($(last_table_row).attr('class').indexOf('even_step_phase') != -1) {
      $(current_table_row).addClass("odd_step_phase")
    } else {
      $(current_table_row).addClass("even_step_phase")
    }

    $(last_table_row).after($(current_table_row));
    stepForm.hasClass('procedure_form') ? $('#steps_list').find('tr.listable.parent_' + procedure_step_id + '.procedure_step:last').nextAll('table').remove() : $('#steps_list').find('tr.listable:last').nextAll('table').remove()

    update_request_duration();
  }
}

function showHideReorderStepsLinks() {
  var tbodySteps = $('#steps_list').find('tbody tr.step').length;
  var theadSteps = $('#steps_list').find('thead tr.step').length;
  if ($('#steps_list').find('thead tr.step').html() == null) {
    if (tbodySteps > 0) {
      $('a#reorder_steps').show();
    } else {
      $('a#reorder_steps').hide();
    }
  } else {
    if (theadSteps > 1) {
      $('a#reorder_steps').show();
    } else {
      $('a#reorder_steps').hide();
    }
  }
}

function alert_owner(step_id) {

  var current_step_row = $("#steps_list td.step_status_complete div.step_" + step_id).parent('td').parent('tr');
  var current_step_type = $("#steps_list td.step_status_complete div.step_" + step_id).parent('td').parent('tr').find("span.step_owner").attr("different_level_from_previous");
  var current_user = $.trim($("body.requests #current_user_name").attr("value")).split(",");
  var current_user_step_position;
  var current_user_step_name;
  var owner;
  var flag = 0;
  var current_user_flag = 0;

  $("#step_owner_message").html("");

  $(current_step_row).nextAll("tr").find("span.step_owner").each(function (index, value) {
    if (flag == 0) {
      if ($(value).attr("different_level_from_previous") == "true") {
        return false;
      } else {
        if ($(value).parent("td").prevAll("td.step_status_ready:first").html() != null || $(value).parent("td").prevAll("td.step_status_in_process:first").html() != null) {
          flag = 1;
        }
      }
    }
  });

  if (current_step_type == "false") {
    $(current_step_row).prevAll("tr").find("td.step_status_ready:first").each(function (index, value) {
      if ($.trim($(value).attr("class")) == "status step_status_ready") {
        flag = 1;
      }
    });

    $(current_step_row).prevAll("tr").find("td.step_status_in_process:first").each(function (index, value) {
      if ($(value).attr("class") == "status step_status_in_process") {
        flag = 1;
      }
    });
  }

  if (flag == 0) {
    var step_position;
    var step_name;
    var alert_step_id;
    $("#steps_list").find("tr.incomplete_step td.step_status_ready").parent('tr').find('span.step_owner').each(function (index, value) {
      owner = $.trim($(value).html());
      owner = owner.split(" ");

      if ($.trim(owner[0]) == $.trim(current_user[1]) && $.trim(owner[1]) == $.trim(current_user[0])) {
        if (current_user_flag == 0) {
          alert_step_id = $(value).parent("td").parent("tr").find("td.step_status_ready").find("div.inline_tiny_step_buttons:first").attr("class").replace(/[^0-9]/g, '');
          alert_step_position = $(value).parent("td").parent("tr").find("td.step_position:first div.step_numbers_p:first").html();
          alert_step_name = $(value).parent("td").parent("tr").find("td.step_name").html();

          step_position = '<a href="#" id="go_to_step" rel="' + alert_step_id + '" >Step#' + alert_step_position + '</a>'
          step_name = alert_step_name;

          current_user_flag = 1;
        }
        $("#step_owner_message").html(step_position + " " + step_name + "  is ready to start" + "<span title='close' class='fr close' onclick='($(this).parent().hide())' style='text-indent:9999;'></span>");
        $("#step_owner_message").attr('class', 'step_owner_message');
      }
    });
  } else {
    return false;
  }
}

function alert_owner_step_ready(step_id) {
  var step_row = get_step_row(step_id);
  if (is_step_owner(step_id) && step_row.find('.state_ready').length > 0) {
    var step_position = step_row.find("div.step_numbers_p:first").html();
    var step_name = step_row.find("td.step_name").html();

    var message_html = $('#step_owner_message_tpl').html();
    message_html = message_html.replace('{step_id}', step_id).replace('{step_position}', step_position);

    var owner_message_el = $("#step_owner_message");
    owner_message_el.html(message_html);
    owner_message_el.find('.close').click(function () {
      $(this).parent().remove();
    });
  }
}

function get_step_row(step_id) {
  return $('#steps_list .step_' + step_id).closest('tr');
}

function is_step_owner(step_id) {
  var step_row = get_step_row(step_id),
      current_user = $.trim($("body.requests #current_user_name").attr("value")).split(","),
      owner = $.trim(step_row.find('span.step_owner').html()).split(" ");
  return $.trim(owner[0]) == $.trim(current_user[1]) && $.trim(owner[1]) == $.trim(current_user[0]);
}

function alert_owner_simplified(step_id) {
  var current_user = $.trim($("body.requests #current_user_name").attr("value")).split(",");
  var owner;
  var flag = 0;
  var current_user_flag = 0;


  if (flag == 0) {
    var step_position;
    var step_name;
    var alert_step_id;
    $("#steps_list").find("tr.incomplete_step td.step_status_ready").parent('tr').find('span.step_owner').each(function (index, value) {
      owner = $.trim($(value).html());
      owner = owner.split(" ");

      if ($.trim(owner[0]) == $.trim(current_user[1]) && $.trim(owner[1]) == $.trim(current_user[0])) {
        if (current_user_flag == 0) {
          alert_step_id = $(value).parent("td").parent("tr").find("td.step_status_ready").find("div.buttons input:first").attr("id").replace(/[^0-9]/g, '');
          alert_step_position = $(value).parent("td").parent("tr").find("td.step_position:first div.step_numbers_p:first").html();
          alert_step_name = $(value).parent("td").parent("tr").find("td.step_name").html();

          step_position = '<a href="#" id="go_to_step" rel="' + alert_step_id + '" >Step#' + alert_step_position + '</a>'
          step_name = alert_step_name;

          current_user_flag = 1;
        }
        $("#step_owner_message").html(step_position + " " + step_name + "  is ready to start" + "<span title='close' class='fr close' onclick='($(this).parent().hide())' style='text-indent:9999;'></span>");
        $("#step_owner_message").attr('class', 'step_owner_message');
      }
    });
  } else {
    return false;
  }
}

function showArtifactPath(version) {
  if (version.val() == "") {
    $("#version_artifact_url").html("")
  } else {
    var request_id = $('#request_number').val();
    var step_id = $('#Step_id').val();
    var url = url_prefix + '/environment/metadata/version_tags/' + version.val() + '/artifact_url';
    $.get(url, function (versions) {
      $("#version_artifact_url").html("Artifacts: <a href=" + versions + " target=\"_blank\" >" + versions + "</a>");
    }, 'html');
  }
}

function loadVersions() {
  var ic_id = $("#step_component_id").val();
  var step_id = $('#Step_id').val();
  var request_id = $('#request_number').val();
  var url = url_prefix + request_id + '/steps/' + step_id + '/versions_for_component';
  $.get(url, function (versions) {
    $("#step_tag_version_id").html(versions);
  });
  //$("#step_version").show();
}

function reset_estimate_start_and_complete_dates() {
  // start time input
  /* $('.step_form #step_start_by_meridian, .procedure_step_form #step_start_by_meridian').val('');
   $('.step_form #step_start_by_minute, .procedure_step_form #step_start_by_minute').val('');
   $('.step_form #step_start_by_hour, .procedure_step_form #step_start_by_hour').val('');
   $('.step_form #step_start_by_date, .procedure_step_form #step_start_by_date').val('');*/
  // end time inputs
  $('.step_form #step_complete_by_meridian, .procedure_step_form #step_complete_by_meridian').val('');
  $('.step_form #step_complete_by_minute, .procedure_step_form #step_complete_by_minute').val('');
  $('.step_form #step_complete_by_hour, .procedure_step_form #step_complete_by_hour').val('');
  $('.step_form #step_complete_by_date, .procedure_step_form #step_complete_by_date').val('');
}

function estimate_time_on_start_and_complete_dates() {
  var bg_class = '';
  var cal_hrs = '';
  var cal_min = '';
  // start time inputs
  var s_md = $('.step_form #step_start_by_meridian, .procedure_step_form #step_start_by_meridian').val();
  var s_m = $('.step_form #step_start_by_minute, .procedure_step_form #step_start_by_minute').val();
  var s_h = $('.step_form #step_start_by_hour, .procedure_step_form #step_start_by_hour').val();
  var s_d = $('.step_form #step_start_by_date, .procedure_step_form #step_start_by_date').val();
  // end time inputs
  var c_md = $('.step_form #step_complete_by_meridian, .procedure_step_form #step_complete_by_meridian').val();
  var c_m = $('.step_form #step_complete_by_minute, .procedure_step_form #step_complete_by_minute').val();
  var c_h = $('.step_form #step_complete_by_hour, .procedure_step_form #step_complete_by_hour').val();
  var c_d = $('.step_form #step_complete_by_date, .procedure_step_form #step_complete_by_date').val();

  if (s_d != '' && c_d != '') {
    if (s_h != '' && s_m != '' && s_md != '') {
      s_d = s_d + ' ' + s_h + ':' + s_m + ' ' + s_md;
    } else {
      s_d = s_d + ' 12:00 PM';
    }
    if (c_h != '' && c_m != '' && c_md != '') {
      c_d = c_d + ' ' + c_h + ':' + c_m + ' ' + c_md;
    } else {
      c_d = c_d + ' 12:00 PM';
    }

    $.ajax({
      url: $('#estimate_calculation_url').val(),
      type: 'GET',
      dataType: 'script',
      data: {
        "c_d": c_d,
        "s_d": s_d
      },
      success: function (data) {
        if (data != '') {
          var cal_time = data.split(",");
          $('.step_estimate #step_estimate_hours').val(cal_time[0]);
          $('.step_estimate #step_estimate_minutes').val(cal_time[1]);
        } else {
          bg_class = '';
          /*with_bg*/
        }
        $('.step_estimate #step_estimate_hours').attr('class', bg_class);
        $('.step_estimate #step_estimate_minutes').attr('class', bg_class);
      }
    });
    //select step time radio button
    $('input[name="step_time"]').attr('checked', '');
    $('input[id="step_time_custom"]').attr('checked', 'checked');
  }
}

/* Multipart data formation*/
function buildMultipartPost(form) {
  var data = new FormData(),
      post = $(form).serializeArray(),
      totalSize = 0;
  /*Merge form data with selected tree node data, if tree is present in the form*/
  var dt = $(".tree_renderer").dynatree("getTree").serializeArray();
  $.each(dt, function () {
    post = post.concat({name: this.name + "[]", value: this.value});
  });

  /*convert serialized array to form data object collection*/
  $.each(post,
      function (ind, obj) {
        data.append(obj.name, obj.value);
      });
  /*collecting attachment data*/
  $(":file", form).each(
      function () {
        var field = $(this),
            node = field.get(0);

        if (node.files[0]) {
          data.append(field.attr("name"), node.files[0]);
          totalSize = totalSize + node.files[0].fileSize;
        }

      });

  return [data, totalSize];
}

function showInnerWaitingWithOverlay() {
  $('#inside_facebox_overlaydiv').attr('style', 'display:block !important');
  $('#wait_inside_facebox').attr('style', 'display:block !important');
}

function hideInnerWaitingWithOverlay() {
  $('#inside_facebox_overlaydiv').attr('style', 'display:none !important');
  $('#wait_inside_facebox').attr('style', 'display:none !important');
}
function tableArgumentPageSelectCallback(page_index, container) {
  if (typeof container != 'undefined') {
    var container_id = '';
    if (typeof container.id == 'undefined') {
      container_id = container.attr('id').match(/[0-9]+$/)[0];
    } else {
      container_id = container.id.match(/[0-9]+$/)[0];
    }
    selected_arguments = JSON.parse($("#table_argument_with_pagination_container_" + container_id).attr("selected_arguments"))
    $.ajax({
      type: "POST",
      data: {page: page_index, argument_id: container_id,
        step_obj: $('#argument_grid').data('step_obj'),
        argument_value: $('#table_arg_' + container_id).attr("argument_value"),
        per_page: $('#table_arg_' + container_id).attr("per_page"),
        source_argument_value: selected_arguments},
      url: url_prefix + '/environment/scripts/get_table_elements',
      complete: function (data) {
        if ($("#argument_table_pagination_" + container_id).attr("argument_name") == "Contents") {
          // Disable package reference check box
          $("input[type='checkbox'][argument_name='Contents']").each(function () {
            $(this).attr("disabled", true).attr("checked", true);
            original_elem_id = $(this).attr("id")
            var hidden = $('<input type="hidden" id="' + $(this).attr('id') + '" value="'
                + $(this).val() + '" name="'
                + $(this).attr('name')
                + '"/>').insertAfter($(this));
          });
        }
      }
    });
  }
}

function render_output_step_view(script_parameter_type) {
  $.get(url_prefix + "/steps/render_output_step_view", {
    "parameter_type": script_parameter_type,
    "step_id": $("#output_step_id").val(),
    "script_id": $("#output_script_id").val(),
    "installed_component_id": $("#output_installed_component_id").val()
  }, function (data) {
    hideInnerWaitingWithOverlay();
    $("#step_output_area").html(data);
    updateTargetArgumentId();
    triggerResourceAutomation();
    if (script_parameter_type == "Input") {
      $("#step_output_area").find(".step_script_argument").attr("disabled", true);
    }
    $("#step_output_area").find("input[type='checkbox']").attr("disabled", true);
  });
}

function restoreSelectionOfCheckboxesForTableArgument(argumentId) {
  var selected_ids = [];

  if ($('#table_arg_' + argumentId).attr('argument_value')) {
    var selected_values = JSON.parse($('#table_arg_' + argumentId).attr('argument_value'));
    $.each(selected_values, function (index, id) {
      if ($('#arg_in_data_list_for_table_' + argumentId).find('#argument_' + argumentId + '_' + id).length == 0) {
        $('<input type="hidden" value="' + id + '" name="argument[' + argumentId + '][]" id="argument_' + argumentId + '_' + id + '">').appendTo('#arg_in_data_list_for_table_' + argumentId);
      }
    });
  }

  if ($('#arg_in_data_list_for_table_' + argumentId).children('input').length > 0) {
    $('#arg_in_data_list_for_table_' + argumentId).children('input').each(function () {
      selected_ids.push($(this).val());
    });
  }

  var selected_id = '';
  $('#table_arg_' + argumentId + ' tr td input').each(function () {
    selected_id = $(this).val();
    if (($.inArray(selected_id, selected_ids) != -1)) {
      $(this).attr("checked", "checked");
    }
  })
}

function can_delete_step(step_id) {
  var responseMsg = "";
  $.ajax({
    type: 'get',
    url: url_prefix + '/steps/' + step_id + '/can_delete_step',
    dataType: 'text',
    async: false
  }).done(function (data) {
    responseMsg = data;
  });
  return confirm(responseMsg);
}
